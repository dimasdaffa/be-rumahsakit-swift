import Fluent
import Vapor
import VaporToOpenAPI

struct AppointmentController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let appointments = routes.grouped("api", "appointments")
        appointments.get(use: index).openAPI(summary: "List appointments")
        appointments.get("today", use: getToday).openAPI(summary: "List today's appointments")
        appointments.post(use: create).openAPI(summary: "Book an appointment", body: .type(CreateAppointmentRequest.self))
        appointments.get(":id", use: show).openAPI(summary: "Get an appointment")
        appointments.patch(":id", use: reschedule).openAPI(summary: "Reschedule an appointment", body: .type(RescheduleAppointmentRequest.self))
        appointments.post(":id", "cancellation-requests", use: requestCancellation)
            .openAPI(summary: "Request appointment cancellation", body: .type(CancelAppointmentRequest.self))
        appointments.delete(":id", use: delete).openAPI(summary: "Delete an appointment immediately")
        appointments.grouped(CheckRole(requiredRole: .doctor)).put(":id", "complete", use: complete)
            .openAPI(summary: "Complete an appointment")
    }

    @Sendable
    func index(req: Request) async throws -> [AppointmentResponse] {
        try await list(req: req, date: nil)
    }

    @Sendable
    func getToday(req: Request) async throws -> [AppointmentResponse] {
        try await list(req: req, date: ClinicTime.dayString(Date()))
    }

    private func list(req: Request, date: String?) async throws -> [AppointmentResponse] {
        let user = try req.auth.require(User.self)
        let query = Appointment.query(on: req.db).with(\.$doctor)
        if user.role == .doctor {
            guard let doctor = try await Doctor.query(on: req.db).filter(\.$user.$id == user.requireID()).first() else { return [] }
            query.filter(\.$doctor.$id == doctor.id!).with(\.$patient)
        } else if user.role == .patient {
            query.filter(\.$patient.$id == user.id!)
        } else {
            query.with(\.$patient)
        }
        if let status = req.query[String.self, at: "status"] { query.filter(\.$status == status) }
        if let date { query.filter(\.$date == date) }
        return try await query.sort(\.$date, .descending).sort(\.$time, .descending).all().map(AppointmentResponse.init)
    }

    @Sendable
    func create(req: Request) async throws -> AppointmentResponse {
        let patientId = try req.auth.require(User.self).requireID()
        let input = try req.content.decode(CreateAppointmentRequest.self)
        let reason = input.reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = req.headers.first(name: "Idempotency-Key")
        guard !reason.isEmpty, reason.utf8.count <= 255, (input.complaints?.utf8.count ?? 0) <= 255,
              key.map({ !$0.isEmpty && $0.utf8.count <= 128 }) ?? true else { throw Abort(.badRequest) }

        return try await req.db.transaction { database in
            try await BookingSlots.lockDoctor(input.doctorId, on: database)
            if let key, let existing = try await Appointment.query(on: database)
                .filter(\.$doctor.$id == input.doctorId).filter(\.$patient.$id == patientId)
                .filter(\.$bookingKey == key).with(\.$doctor).first() {
                return try AppointmentResponse(existing)
            }
            try await BookingSlots.requireAvailable(doctorId: input.doctorId, date: input.date, time: input.time, on: database)
            let appointment = Appointment(
                patientId: patientId, doctorId: input.doctorId, date: input.date,
                time: input.time, reason: reason, complaints: input.complaints
            )
            appointment.bookingKey = key
            try await appointment.create(on: database)
            try await appointment.$doctor.load(on: database)
            return try AppointmentResponse(appointment)
        }
    }

    @Sendable
    func show(req: Request) async throws -> AppointmentResponse {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require("id", as: UUID.self)
        let query = Appointment.query(on: req.db).filter(\.$id == id).with(\.$doctor)
        if user.role != .patient { query.with(\.$patient) }
        guard let appointment = try await query.first() else { throw Abort(.notFound) }
        try authorize(user, appointment, allowDoctor: true)
        return try AppointmentResponse(appointment)
    }

    @Sendable
    func reschedule(req: Request) async throws -> AppointmentResponse {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(RescheduleAppointmentRequest.self)
        return try await change(req) { appointment, database in
            try authorize(user, appointment)
            guard ["pending", "approved"].contains(appointment.status), isFuture(appointment) else { throw Abort(.conflict) }
            guard appointment.date != input.date || appointment.time != input.time else { return }
            try await BookingSlots.requireAvailable(
                doctorId: appointment.$doctor.id, date: input.date, time: input.time, excluding: appointment.id, on: database
            )
            appointment.date = input.date
            appointment.time = input.time
            appointment.status = "pending"
        }
    }

    @Sendable
    func requestCancellation(req: Request) async throws -> AppointmentResponse {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(CancelAppointmentRequest.self)
        let reason = input.reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reason.isEmpty, reason.utf8.count <= 255, (input.note?.utf8.count ?? 0) <= 255 else { throw Abort(.badRequest) }
        return try await change(req) { appointment, _ in
            try authorize(user, appointment)
            if appointment.status == "cancellation_requested", appointment.cancellationReason == reason,
               appointment.cancellationNote == input.note { return }
            guard ["pending", "approved"].contains(appointment.status), isFuture(appointment) else { throw Abort(.conflict) }
            appointment.preCancellationStatus = appointment.status
            appointment.status = "cancellation_requested"
            appointment.cancellationReason = reason
            appointment.cancellationNote = input.note
        }
    }

    @Sendable
    func decideCancellation(req: Request) async throws -> AppointmentResponse {
        let input = try req.content.decode(DecideCancellationRequest.self)
        return try await change(req) { appointment, database in
            guard appointment.status == "cancellation_requested", let previous = appointment.preCancellationStatus else {
                throw Abort(.conflict)
            }
            appointment.status = input.approved ? "cancelled" : previous
            appointment.preCancellationStatus = nil
            try await PatientNotification.appointmentChanged(
                appointment, type: input.approved ? "cancelled" : "cancellation_declined", on: database
            )
        }
    }

    @Sendable
    func approve(req: Request) async throws -> AppointmentResponse {
        try await decideBooking(req, status: "approved")
    }

    @Sendable
    func reject(req: Request) async throws -> AppointmentResponse {
        try await decideBooking(req, status: "rejected")
    }

    @Sendable
    func complete(req: Request) async throws -> AppointmentResponse {
        let user = try req.auth.require(User.self)
        return try await change(req) { appointment, _ in
            try authorize(user, appointment, allowDoctor: true)
            guard ["approved", "completed"].contains(appointment.status) else { throw Abort(.conflict) }
            appointment.status = "completed"
        }
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require("id", as: UUID.self)
        return try await withLockedAppointment(id, on: req.db) { appointment, database in
            try authorize(user, appointment, allowDoctor: true)
            if user.role == .patient && appointment.status == "completed" { throw Abort(.conflict) }
            try await appointment.delete(on: database)
            return .noContent
        }
    }

    private func decideBooking(_ req: Request, status: String) async throws -> AppointmentResponse {
        try await change(req) { appointment, database in
            if appointment.status == status { return }
            guard appointment.status == "pending" else { throw Abort(.conflict) }
            appointment.status = status
            try await PatientNotification.appointmentChanged(appointment, type: status, on: database)
        }
    }

    private func change(
        _ req: Request, _ operation: @escaping @Sendable (Appointment, any Database) async throws -> Void
    ) async throws -> AppointmentResponse {
        let id = try req.parameters.require("id", as: UUID.self)
        return try await withLockedAppointment(id, on: req.db) { appointment, database in
            try await operation(appointment, database)
            try await appointment.save(on: database)
            return try AppointmentResponse(appointment)
        }
    }

    func withLockedAppointment<T: Sendable>(
        _ id: UUID, on db: any Database, _ operation: @escaping @Sendable (Appointment, any Database) async throws -> T
    ) async throws -> T {
        guard let doctorId = try await Appointment.find(id, on: db)?.$doctor.id else { throw Abort(.notFound) }
        return try await db.transaction { database in
            try await BookingSlots.lockDoctor(doctorId, on: database)
            guard let appointment = try await Appointment.query(on: database).filter(\.$id == id).with(\.$doctor).first()
            else { throw Abort(.notFound) }
            return try await operation(appointment, database)
        }
    }

    private func authorize(_ user: User, _ appointment: Appointment, allowDoctor: Bool = false) throws {
        if user.role == .admin || user.id == appointment.$patient.id { return }
        if allowDoctor, user.role == .doctor, appointment.$doctor.value?.$user.id == user.id { return }
        throw Abort(.forbidden)
    }

    private func isFuture(_ appointment: Appointment) -> Bool {
        guard let day = ClinicTime.day(appointment.date), let minute = ClinicTime.minute(appointment.time) else { return false }
        return day.addingTimeInterval(Double(minute * 60)) > Date()
    }
}

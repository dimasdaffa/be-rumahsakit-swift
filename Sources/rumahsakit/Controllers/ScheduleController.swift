import Vapor
import Fluent
import VaporToOpenAPI

struct ScheduleController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let schedules = routes.grouped("api", "schedules")
        
        // Authenticated users can read weekly practice hours.
        schedules.get(use: index)
            .openAPI(summary: "List doctor schedules")

        // DOCTOR ONLY: Management
        let doctorGroup = schedules.grouped(CheckRole(requiredRole: .doctor))
        
        doctorGroup.post(use: create)
            .openAPI(
                summary: "Add a schedule slot (Doctor only)",
                body: .type(CreateScheduleRequest.self)
            )
            
        doctorGroup.put(":id", use: update)
            .openAPI(summary: "Update schedule (Doctor only)")
            
        doctorGroup.delete(":id", use: delete)
            .openAPI(summary: "Delete schedule (Doctor only)")
    }

    // GET /api/schedules?doctorId=...
    @Sendable
    func index(req: Request) async throws -> [Schedule] {
        let query = Schedule.query(on: req.db)
        
        // Filter by Doctor ID if provided
        if let doctorId = req.query[UUID.self, at: "doctorId"] {
            query.filter(\.$doctor.$id == doctorId)
        }
        
        return try await query.all()
    }

    @Sendable
    func create(req: Request) async throws -> Schedule {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(CreateScheduleRequest.self)
        let doctorId = try await PatientAccess.doctorId(for: user, on: req.db)
        try validate(day: input.dayOfWeek, start: input.startTime, end: input.endTime)
        return try await req.db.transaction { database in
            try await BookingSlots.lockDoctor(doctorId, on: database)
            let schedule = Schedule(doctorId: doctorId, dayOfWeek: input.dayOfWeek, startTime: input.startTime,
                                    endTime: input.endTime, isAvailable: input.isAvailable)
            try await schedule.create(on: database)
            return schedule
        }
    }

    @Sendable
    func update(req: Request) async throws -> Schedule {
        let input = try req.content.decode(UpdateScheduleRequest.self)
        return try await mutate(req) { schedule, database in
            if let day = input.dayOfWeek { schedule.dayOfWeek = day }
            if let start = input.startTime { schedule.startTime = start }
            if let end = input.endTime { schedule.endTime = end }
            if let available = input.isAvailable { schedule.isAvailable = available }
            try validate(day: schedule.dayOfWeek, start: schedule.startTime, end: schedule.endTime)
            try await schedule.update(on: database)
            return schedule
        }
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        try await mutate(req) { schedule, database in
            try await schedule.delete(on: database)
            return .noContent
        }
    }

    private func mutate<T: Sendable>(
        _ req: Request, _ change: @escaping @Sendable (Schedule, any Database) async throws -> T
    ) async throws -> T {
        let user = try req.auth.require(User.self)
        let doctorId = try await PatientAccess.doctorId(for: user, on: req.db)
        let id = try req.parameters.require("id", as: UUID.self)
        return try await req.db.transaction { database in
            try await BookingSlots.lockDoctor(doctorId, on: database)
            guard let schedule = try await Schedule.find(id, on: database) else { throw Abort(.notFound) }
            guard schedule.$doctor.id == doctorId else { throw Abort(.forbidden) }
            return try await change(schedule, database)
        }
    }

    private func validate(day: String, start: String, end: String) throws {
        guard BookingSlots.weekdays.contains(day.lowercased()), let start = ClinicTime.minute(start),
              let end = ClinicTime.minute(end), end - start >= BookingSlots.duration else {
            throw Abort(.badRequest, reason: "Specify a weekday and at least 30 minutes of practice hours")
        }
    }
}

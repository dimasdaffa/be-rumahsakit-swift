import Fluent
import Vapor
import VaporToOpenAPI

struct AppointmentController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let appointments = routes.grouped("api", "appointments")

        // LIST
        appointments.get(use: index)
            .openAPI(summary: "List Appointments")

        // CREATE
        appointments.post(use: create)
            .openAPI(
                summary: "Book an Appointment",
                body: .type(CreateAppointmentRequest.self)
            )

        // DETAILS
        appointments.get(":id", use: show)
            .openAPI(summary: "Get Appointment Details")

        // DELETE (Cancel) 
        appointments.delete(":id", use: delete)
            .openAPI(summary: "Cancel/Delete an appointment")

        // COMPLETE (Doctor Only) 
        let doctorGroup = appointments.grouped(CheckRole(requiredRole: .doctor))
        doctorGroup.put(":id", "complete", use: complete)
            .openAPI(summary: "Mark appointment as completed (Doctor only)")
    }

    // 1. LIST APPOINTMENTS 📋
    @Sendable
    func index(req: Request) async throws -> [Appointment] {
        let user = try req.auth.require(User.self)

        if user.role == .admin {
            // Admin: Show ALL
            return try await Appointment.query(on: req.db)
                .with(\.$doctor)
                .with(\.$patient)
                .all()

        } else if user.role == .doctor {
            // Doctor: Show appointments assigned to me
            // We must find the "Doctor" record that matches this "User" email
            guard
                let doctorRecord = try await Doctor.query(on: req.db)
                    .filter(\.$email == user.email)
                    .first()
            else {
                return []  // No doctor profile found for this user
            }

            return try await Appointment.query(on: req.db)
                .filter(\.$doctor.$id == doctorRecord.id!)
                .with(\.$patient)  // Doctor needs to know who the patient is
                .all()

        } else {
            // Patient: Show only MY appointments
            return try await Appointment.query(on: req.db)
                .filter(\.$patient.$id == user.id!)
                .with(\.$doctor)  // Patient needs to know who the doctor is
                .all()
        }
    }

    // 2. BOOK NEW APPOINTMENT ➕
    @Sendable
    func create(req: Request) async throws -> Appointment {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(CreateAppointmentRequest.self)

        let appointment = Appointment(
            patientId: user.id!,
            doctorId: input.doctorId,
            date: input.date,
            time: input.time,
            reason: input.reason,
            complaints: input.complaints  // Added from Step 1
        )

        try await appointment.save(on: req.db)
        return appointment
    }

    // 3. APPROVE APPOINTMENT (Admin Only) ✅
    @Sendable
    func approve(req: Request) async throws -> Appointment {
        guard let appointment = try await Appointment.find(req.parameters.get("id"), on: req.db)
        else {
            throw Abort(.notFound)
        }
        appointment.status = "approved"
        try await appointment.save(on: req.db)
        return appointment
    }

    // 4. REJECT APPOINTMENT (Admin Only) ❌
    @Sendable
    func reject(req: Request) async throws -> Appointment {
        guard let appointment = try await Appointment.find(req.parameters.get("id"), on: req.db)
        else {
            throw Abort(.notFound)
        }
        appointment.status = "rejected"
        try await appointment.save(on: req.db)
        return appointment
    }

    // 5. SHOW SINGLE APPOINTMENT 🔍
    @Sendable
    func show(req: Request) async throws -> Appointment {
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        guard
            let appointment = try await Appointment.query(on: req.db)
                .filter(\.$id == id)
                .with(\.$doctor)
                .with(\.$patient)
                .first()
        else {
            throw Abort(.notFound)
        }

        let user = try req.auth.require(User.self)

        // Security Check: Admin OR Owner (Patient) OR Assigned Doctor
        var isAuthorized = false

        if user.role == .admin { isAuthorized = true }
        if appointment.$patient.id == user.id { isAuthorized = true }

        // Check if user is the assigned doctor
        if user.role == .doctor {
            if let doctorRecord = try await Doctor.query(on: req.db).filter(\.$email == user.email)
                .first(),
                doctorRecord.id == appointment.$doctor.id
            {
                isAuthorized = true
            }
        }

        if !isAuthorized {
            throw Abort(.forbidden, reason: "You are not allowed to view this appointment.")
        }

        return appointment
    }

    // DELETE /api/appointments/:id
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)

        guard let appointment = try await Appointment.find(req.parameters.get("id"), on: req.db)
        else {
            throw Abort(.notFound)
        }

        // 1. ADMIN: Can delete anything
        if user.role == .admin {
            try await appointment.delete(on: req.db)
            return .noContent
        }

        // 2. PATIENT: Can only delete THEIR OWN appointment
        if user.role == .patient {
            // Check ownership
            guard appointment.$patient.id == user.id else {
                throw Abort(.forbidden, reason: "You can only cancel your own appointments")
            }
            // Optional: Prevent cancelling if status is already 'completed'
            if appointment.status == "completed" {
                throw Abort(.badRequest, reason: "Cannot cancel a completed appointment")
            }
        }

        // 3. DOCTOR: Can only delete appointments ASSIGNED TO THEM
        if user.role == .doctor {
            // We need to find the Doctor profile linked to this User
            guard
                let doctorProfile = try await Doctor.query(on: req.db)
                    .filter(\.$user.$id == user.id!)
                    .first()
            else {
                throw Abort(.forbidden, reason: "Doctor profile not found")
            }

            // Check assignment
            guard appointment.$doctor.id == doctorProfile.id else {
                throw Abort(.forbidden, reason: "You can only cancel appointments assigned to you")
            }
        }

        try await appointment.delete(on: req.db)
        return .noContent
    }

    // PUT /api/appointments/:id/complete
    @Sendable
    func complete(req: Request) async throws -> Appointment {
        let user = try req.auth.require(User.self)
        
        guard let appointment = try await Appointment.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Verify this appointment belongs to the logged-in Doctor
        // 1. Get Doctor Profile
        guard let doctorProfile = try await Doctor.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .first() else {
            throw Abort(.forbidden, reason: "Doctor profile not found")
        }
        
        // 2. Check assignment
        guard appointment.$doctor.id == doctorProfile.id else {
            throw Abort(.forbidden, reason: "You can only complete your own appointments")
        }
        
        appointment.status = "completed"
        try await appointment.save(on: req.db)
        
        return appointment
    }
}

import Vapor
import Fluent
import VaporToOpenAPI

struct AppointmentController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let appointments = routes.grouped("api", "appointments")
        
        appointments.get(use: index)
        
        appointments.post(use: create)
            .openAPI(
                summary: "Book an Appointment",
                body: .type(CreateAppointmentRequest.self)
            )
            
        appointments.get(":id", use: show)
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
            guard let doctorRecord = try await Doctor.query(on: req.db)
                .filter(\.$email == user.email)
                .first() else {
                return [] // No doctor profile found for this user
            }
            
            return try await Appointment.query(on: req.db)
                .filter(\.$doctor.$id == doctorRecord.id!)
                .with(\.$patient) // Doctor needs to know who the patient is
                .all()
                
        } else {
            // Patient: Show only MY appointments
            return try await Appointment.query(on: req.db)
                .filter(\.$patient.$id == user.id!)
                .with(\.$doctor) // Patient needs to know who the doctor is
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
            complaints: input.complaints // Added from Step 1
        )
        
        try await appointment.save(on: req.db)
        return appointment
    }

    // 3. APPROVE APPOINTMENT (Admin Only) ✅
    @Sendable
    func approve(req: Request) async throws -> Appointment {
        guard let appointment = try await Appointment.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        appointment.status = "approved"
        try await appointment.save(on: req.db)
        return appointment
    }

    // 4. REJECT APPOINTMENT (Admin Only) ❌
    @Sendable
    func reject(req: Request) async throws -> Appointment {
        guard let appointment = try await Appointment.find(req.parameters.get("id"), on: req.db) else {
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

        guard let appointment = try await Appointment.query(on: req.db)
            .filter(\.$id == id)
            .with(\.$doctor)
            .with(\.$patient)
            .first() else {
            throw Abort(.notFound)
        }
        
        let user = try req.auth.require(User.self)
        
        // Security Check: Admin OR Owner (Patient) OR Assigned Doctor
        var isAuthorized = false
        
        if user.role == .admin { isAuthorized = true }
        if appointment.$patient.id == user.id { isAuthorized = true }
        
        // Check if user is the assigned doctor
        if user.role == .doctor {
            if let doctorRecord = try await Doctor.query(on: req.db).filter(\.$email == user.email).first(),
               doctorRecord.id == appointment.$doctor.id {
                isAuthorized = true
            }
        }
        
        if !isAuthorized {
            throw Abort(.forbidden, reason: "You are not allowed to view this appointment.")
        }
        
        return appointment
    }
}
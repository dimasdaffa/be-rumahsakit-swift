import Vapor
import Fluent
import VaporToOpenAPI

struct AppointmentController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let appointments = routes.grouped("api", "appointments")
        
        // GET /api/appointments (See my own appointments)
        appointments.get(use: index)
        
        // POST /api/appointments (Book a new one)
        appointments.post(use: create)
            .openAPI(
                summary: "Book an Appointment",
                body: .type(CreateAppointmentRequest.self)
            )
    }

    // 1. LIST MY APPOINTMENTS 📋
    @Sendable
    func index(req: Request) async throws -> [Appointment] {
        // Get the logged-in user
        let user = try req.auth.require(User.self)
        
        // If Admin, show ALL. If Patient, show ONLY THEIRS.
        if user.role == .admin {
            return try await Appointment.query(on: req.db)
                .with(\.$doctor) // Include Doctor details
                .with(\.$patient) // Include Patient details
                .all()
        } else {
            return try await Appointment.query(on: req.db)
                .filter(\.$patient.$id == user.id!)
                .with(\.$doctor)
                .all()
        }
    }

    // 2. BOOK NEW APPOINTMENT ➕
    @Sendable
    func create(req: Request) async throws -> Appointment {
        // Get logged-in user
        let user = try req.auth.require(User.self)
        
        // Decode input
        let input = try req.content.decode(CreateAppointmentRequest.self)
        
        // Create object
        let appointment = Appointment(
            patientId: user.id!,
            doctorId: input.doctorId,
            date: input.date,
            time: input.time,
            reason: input.reason
        )
        
        try await appointment.save(on: req.db)
        return appointment
    }

    // 3. APPROVE APPOINTMENT (Admin Only) ✅
    @Sendable
    func approve(req: Request) async throws -> Appointment {
        // 1. Find the appointment
        guard let appointment = try await Appointment.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // 2. Change Status
        appointment.status = "approved"
        try await appointment.save(on: req.db)
        
        return appointment
    }

    // 4. REJECT APPOINTMENT (Admin Only) ❌
    @Sendable
    func reject(req: Request) async throws -> Appointment {
        // 1. Find the appointment
        guard let appointment = try await Appointment.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // 2. Change Status
        appointment.status = "rejected"
        try await appointment.save(on: req.db)
        
        return appointment
    }
}
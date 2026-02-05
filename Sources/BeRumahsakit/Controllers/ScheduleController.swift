import Vapor
import Fluent
import VaporToOpenAPI

struct ScheduleController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let schedules = routes.grouped("api", "schedules")
        
        // PUBLIC: List all schedules (Patients can see availability)
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

    // POST /api/schedules
    @Sendable
    func create(req: Request) async throws -> Schedule {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(CreateScheduleRequest.self)
        
        // Find Doctor Profile
        guard let doctor = try await Doctor.query(on: req.db).filter(\.$user.$id == user.id!).first() else {
            throw Abort(.forbidden, reason: "Doctor profile not found")
        }
        
        let schedule = Schedule(
            doctorId: doctor.id!,
            dayOfWeek: input.dayOfWeek,
            startTime: input.startTime,
            endTime: input.endTime,
            isAvailable: input.isAvailable
        )
        
        try await schedule.save(on: req.db)
        return schedule
    }

    // PUT /api/schedules/:id
    @Sendable
    func update(req: Request) async throws -> Schedule {
        let user = try req.auth.require(User.self)
        guard let schedule = try await Schedule.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Verify Ownership
        guard let doctor = try await Doctor.query(on: req.db).filter(\.$user.$id == user.id!).first(),
              doctor.id == schedule.$doctor.id else {
            throw Abort(.forbidden)
        }
        
        let input = try req.content.decode(UpdateScheduleRequest.self)
        if let d = input.dayOfWeek { schedule.dayOfWeek = d }
        if let s = input.startTime { schedule.startTime = s }
        if let e = input.endTime { schedule.endTime = e }
        if let a = input.isAvailable { schedule.isAvailable = a }
        
        try await schedule.save(on: req.db)
        return schedule
    }

    // DELETE /api/schedules/:id
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let schedule = try await Schedule.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Verify Ownership
        guard let doctor = try await Doctor.query(on: req.db).filter(\.$user.$id == user.id!).first(),
              doctor.id == schedule.$doctor.id else {
            throw Abort(.forbidden)
        }
        
        try await schedule.delete(on: req.db)
        return .noContent
    }
}
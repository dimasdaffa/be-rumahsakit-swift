import Vapor
import Fluent

struct ScheduleController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let schedules = routes.grouped("api", "schedules")
        
        // GET /api/schedules?doctorId=...
        schedules.get(use: index)
        
        // POST /api/schedules/generate (Auto-create slots for a doctor)
        schedules.post("generate", use: generate)
    }

    // 1. Get Schedules (Optional Filter by Doctor)
    @Sendable
    func index(req: Request) async throws -> [Schedule] {
        if let doctorId = req.query[UUID.self, at: "doctorId"] {
            // Return only schedules for this doctor
            return try await Schedule.query(on: req.db)
                .filter(\.$doctor.$id == doctorId)
                .all()
        }
        return try await Schedule.query(on: req.db).all()
    }

    // 2. Generate Slots (Replaces your frontend loop)
    @Sendable
    func generate(req: Request) async throws -> HTTPStatus {
        struct GeneratePayload: Content {
            var doctorId: UUID
            var date: String // "2024-01-30"
        }
        let payload = try req.content.decode(GeneratePayload.self)
        
        // Standard shifts for your hospital
        let shifts = ["09:00", "10:00", "11:00", "13:00", "14:00", "15:00"]
        
        for time in shifts {
            let schedule = Schedule(
                doctorId: payload.doctorId, 
                date: payload.date, 
                time: time, 
                isAvailable: true
            )
            try await schedule.save(on: req.db)
        }
        
        return .created
    }
}
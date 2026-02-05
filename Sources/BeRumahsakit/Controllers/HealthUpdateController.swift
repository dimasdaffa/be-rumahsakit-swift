import Vapor
import Fluent
import VaporToOpenAPI

struct HealthUpdateController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let health = routes.grouped("api", "health-updates")
        
        // LIST (Patients see own, Doctors see all/specific)
        health.get(use: index)
            .openAPI(summary: "List Health Updates")
        
        // CREATE
        health.post(use: create)
            .openAPI(
                summary: "Log a health update",
                body: .type(CreateHealthUpdateRequest.self)
            )
            
        // DELETE
        health.delete(":id", use: delete)
    }

    // GET /api/health-updates
    @Sendable
    func index(req: Request) async throws -> [HealthUpdate] {
        let user = try req.auth.require(User.self)
        
        if user.role == .patient {
            // Patient: See only MY updates
            return try await HealthUpdate.query(on: req.db)
                .filter(\.$patient.$id == user.id!)
                .sort(\.$date, .descending)
                .all()
        } else {
            // Doctor/Admin: Can see all (or filter by ?patientId=...)
            let query = HealthUpdate.query(on: req.db).with(\.$patient)
            
            if let targetPatientId = req.query[UUID.self, at: "patientId"] {
                query.filter(\.$patient.$id == targetPatientId)
            }
            
            return try await query.sort(\.$date, .descending).all()
        }
    }

    // POST /api/health-updates
    @Sendable
    func create(req: Request) async throws -> HealthUpdate {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(CreateHealthUpdateRequest.self)
        
        // Determine Patient ID
        var targetPatientId = user.id!
        
        // If Doctor/Admin is creating it, they MUST provide patientId
        if user.role != .patient {
            guard let pid = input.patientId else {
                throw Abort(.badRequest, reason: "Doctors must specify patientId")
            }
            targetPatientId = pid
        }
        
        let update = HealthUpdate(
            patientId: targetPatientId,
            date: input.date,
            weight: input.weight,
            height: input.height,
            bloodPressure: input.bloodPressure,
            bloodSugar: input.bloodSugar,
            heartRate: input.heartRate,
            sleepHours: input.sleepHours,
            mood: input.mood,
            notes: input.notes
        )
        
        try await update.save(on: req.db)
        return update
    }
    
    // DELETE /api/health-updates/:id
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let update = try await HealthUpdate.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Only owner or Admin can delete
        if user.role == .patient && update.$patient.id != user.id {
             throw Abort(.forbidden)
        }
        
        try await update.delete(on: req.db)
        return .noContent
    }
}
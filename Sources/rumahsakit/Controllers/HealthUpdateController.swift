import Vapor
import Fluent
import VaporToOpenAPI

struct HealthUpdateController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let health = routes.grouped("api", "health-updates")
        
        // LIST (Patients see own, Doctors see all/specific)
        health.get(use: index)
            .openAPI(summary: "List Health Updates")
        
        health.get(":id", use: detail).openAPI(summary: "Get a health update")

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
        
        let query = HealthUpdate.query(on: req.db)
        if user.role == .patient {
            query.filter(\.$patient.$id == user.id!)
        } else if let targetPatientId = req.query[UUID.self, at: "patientId"] {
            try await PatientAccess.require(user, patientId: targetPatientId, on: req.db)
            query.filter(\.$patient.$id == targetPatientId)
        } else if user.role == .doctor {
            let doctorId = try await PatientAccess.doctorId(for: user, on: req.db)
            let patients = try await Appointment.query(on: req.db).filter(\.$doctor.$id == doctorId)
                .filter(\.$status ~~ ["approved", "completed"]).all(\.$patient.$id)
            guard !patients.isEmpty else { return [] }
            query.filter(\.$patient.$id ~~ Array(Set(patients)))
        }
        let from = req.query[String.self, at: "from"]
        let to = req.query[String.self, at: "to"]
        if let from {
            guard ClinicTime.day(from) != nil else { throw Abort(.badRequest) }
            query.filter(\.$date >= from)
        }
        if let to {
            guard ClinicTime.day(to) != nil, from.map({ $0 <= to }) ?? true else { throw Abort(.badRequest) }
            query.filter(\.$date <= to)
        }
        switch req.query[String.self, at: "metric"] {
        case "bloodPressure": query.filter(\.$bloodPressure != nil)
        case "heartRate": query.filter(\.$heartRate != nil)
        case "weight": query.filter(\.$weight != nil)
        case nil: break
        default: throw Abort(.badRequest, reason: "Unknown metric")
        }
        if let limit = req.query[Int.self, at: "limit"] {
            let page = req.query[Int.self, at: "page"] ?? 1
            guard (1...100).contains(limit), (1...10_000).contains(page) else { throw Abort(.badRequest) }
            query.range(((page - 1) * limit)..<(page * limit))
        }
        return try await query.sort(\.$date, .descending).sort(\.$measuredAt, .descending).sort(\.$createdAt, .descending).all()
    }

    @Sendable
    func detail(req: Request) async throws -> HealthUpdate {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require("id", as: UUID.self)
        guard let update = try await HealthUpdate.find(id, on: req.db) else { throw Abort(.notFound) }
        try await PatientAccess.require(user, patientId: update.$patient.id, on: req.db)
        return update
    }

    // POST /api/health-updates
    @Sendable
    func create(req: Request) async throws -> HealthUpdate {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(CreateHealthUpdateRequest.self)
        
        guard ClinicTime.day(input.date) != nil,
              input.measuredAt.map({ ClinicTime.dayString($0) == input.date }) ?? true,
              input.weight.map({ $0.isFinite && $0 > 0 }) ?? true,
              input.heartRate.map({ $0 > 0 }) ?? true,
              input.bloodPressure.map(Self.isBloodPressure) ?? true else { throw Abort(.badRequest) }

        // Determine Patient ID
        var targetPatientId = user.id!
        
        // If Doctor/Admin is creating it, they MUST provide patientId
        if user.role != .patient {
            guard let pid = input.patientId else {
                throw Abort(.badRequest, reason: "Doctors must specify patientId")
            }
            try await PatientAccess.require(user, patientId: pid, on: req.db)
            guard try await User.find(pid, on: req.db)?.role == .patient else { throw Abort(.notFound) }
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
        
        update.measuredAt = input.measuredAt
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
        if user.role != .admin && update.$patient.id != user.id {
             throw Abort(.forbidden)
        }
        
        try await update.delete(on: req.db)
        return .noContent
    }
    private static func isBloodPressure(_ value: String) -> Bool {
        let parts = value.split(separator: "/", omittingEmptySubsequences: false)
        return parts.count == 2 && parts.allSatisfy { $0.count <= 3 && !$0.isEmpty && $0.utf8.allSatisfy { (48...57).contains($0) } && (Int($0) ?? 0) > 0 }
    }
}

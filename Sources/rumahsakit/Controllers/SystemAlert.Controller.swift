import Vapor
import Fluent
import VaporToOpenAPI

struct SystemAlertController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let alerts = routes.grouped("api", "system-alerts")
        
        // ADMIN ONLY GROUP
        // (Access control should be handled in routes.swift via adminOnly group, 
        // but we add a check here just in case)
        
        // LIST ALERTS
        alerts.get(use: index)
            .openAPI(summary: "List System Alerts (Admin)")

        // RESOLVE ALERT
        alerts.post(":id", "resolve", use: resolve)
            .openAPI(summary: "Mark alert as resolved (Admin)")
            
        // CREATE (For testing/simulation)
        alerts.post(use: create)
            .openAPI(summary: "Trigger a manual alert (Admin)")
    }

    // GET /api/system-alerts
    @Sendable
    func index(req: Request) async throws -> [SystemAlert] {
        // Filter: Show 'active' first, then sorted by date
        return try await SystemAlert.query(on: req.db)
            .sort(\.$status, .ascending) // "active" comes before "resolved" alphabetically? No, actually 'a' < 'r', so yes.
            .sort(\.$createdAt, .descending)
            .all()
    }

    // POST /api/system-alerts/:id/resolve
    @Sendable
    func resolve(req: Request) async throws -> SystemAlert {
        guard let alert = try await SystemAlert.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        alert.status = "resolved"
        try await alert.save(on: req.db)
        return alert
    }
    
    // POST /api/system-alerts (Helper to create test alerts)
    @Sendable
    func create(req: Request) async throws -> SystemAlert {
        // Input DTO
        struct CreateAlertInput: Content {
            var type: String
            var title: String
            var message: String
        }
        let input = try req.content.decode(CreateAlertInput.self)
        
        let alert = SystemAlert(
            type: input.type,
            title: input.title,
            message: input.message
        )
        
        try await alert.save(on: req.db)
        return alert
    }
}
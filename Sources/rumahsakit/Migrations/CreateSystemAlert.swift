import Fluent
import FluentSQL

struct CreateSystemAlert: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Check if table already exists (idempotent migration)
        if let sql = database as? SQLDatabase {
            let tables = try await sql.raw("SHOW TABLES LIKE 'system_alerts'").all()
            guard tables.isEmpty else {
                database.logger.info("Table 'system_alerts' already exists, skipping creation.")
                return
            }
        }
        try await database.schema("system_alerts")
            .id()
            .field("type", .string, .required)  // "info", "warning", "critical"
            .field("title", .string, .required)
            .field("message", .string, .required)
            .field("status", .string, .required)  // "active", "resolved"
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("system_alerts").delete()
    }
}

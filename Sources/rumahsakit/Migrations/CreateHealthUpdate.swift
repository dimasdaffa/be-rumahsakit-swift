import Fluent
import FluentSQL

struct CreateHealthUpdate: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Check if table already exists (idempotent migration)
        if let sql = database as? SQLDatabase {
            let tables = try await sql.raw("SHOW TABLES LIKE 'health_updates'").all()
            guard tables.isEmpty else {
                database.logger.info("Table 'health_updates' already exists, skipping creation.")
                return
            }
        }
        try await database.schema("health_updates")
            .id()
            .field("patient_id", .uuid, .required, .references("users", "id"))
            .field("date", .string, .required) // YYYY-MM-DD
            .field("weight", .double)
            .field("height", .double)
            .field("blood_pressure", .string) // "120/80"
            .field("blood_sugar", .double)
            .field("heart_rate", .int)
            .field("sleep_hours", .double)
            .field("mood", .string)
            .field("notes", .string)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("health_updates").delete()
    }
}
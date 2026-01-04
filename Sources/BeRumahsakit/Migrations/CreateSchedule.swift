import Fluent
import FluentSQL

struct CreateSchedule: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Check if table already exists (idempotent migration)
        if let sql = database as? SQLDatabase {
            let tables = try await sql.raw("SHOW TABLES LIKE 'schedules'").all()
            guard tables.isEmpty else {
                database.logger.info("Table 'schedules' already exists, skipping creation.")
                return
            }
        }
        
        try await database.schema("schedules")
            .id()
            .field("doctor_id", .uuid, .required, .references("doctors", "id")) // 🔗 Foreign Key
            .field("date", .string, .required)
            .field("time", .string, .required)
            .field("is_available", .bool, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("schedules").delete()
    }
}
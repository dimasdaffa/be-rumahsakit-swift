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
            .field("doctor_id", .uuid, .required, .references("doctors", "id"))
            .field("day_of_week", .string, .required) // e.g., "Monday", "Tuesday"
            .field("start_time", .string, .required) // "09:00"
            .field("end_time", .string, .required)   // "17:00"
            .field("is_available", .bool, .required, .sql(.default(true)))
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("schedules").delete()
    }
}
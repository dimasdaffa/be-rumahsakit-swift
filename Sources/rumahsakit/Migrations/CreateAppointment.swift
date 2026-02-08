import Fluent
import FluentSQL

struct CreateAppointment: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Check if table already exists (idempotent migration)
        if let sql = database as? SQLDatabase {
            let tables = try await sql.raw("SHOW TABLES LIKE 'appointments'").all()
            guard tables.isEmpty else {
                database.logger.info("Table 'appointments' already exists, skipping creation.")
                return
            }
        }
        try await database.schema("appointments")
            .id()
            .field("patient_id", .uuid, .required, .references("users", "id"))   // Must be a valid User
            .field("doctor_id", .uuid, .required, .references("doctors", "id")) // Must be a valid Doctor
            .field("date", .string, .required)
            .field("time", .string, .required)
            .field("reason", .string, .required)
            .field("complaints", .string)
            .field("status", .string, .required)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("appointments").delete()
    }
}
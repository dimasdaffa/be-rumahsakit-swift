import Fluent
import FluentSQL

struct CreateMedicalRecord: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Check if table already exists (idempotent migration)
        if let sql = database as? SQLDatabase {
            let tables = try await sql.raw("SHOW TABLES LIKE 'medical_records'").all()
            guard tables.isEmpty else {
                database.logger.info("Table 'medical_records' already exists, skipping creation.")
                return
            }
        }
        try await database.schema("medical_records")
            .id()
            .field("appointment_id", .uuid, .required, .references("appointments", "id"))
            .field("patient_id", .uuid, .required, .references("users", "id"))
            .field("diagnosis", .string, .required)
            .field("symptoms", .string, .required)
            .field("treatment", .string, .required)
            .field("prescription", .string)
            .field("notes", .string)
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("medical_records").delete()
    }
}
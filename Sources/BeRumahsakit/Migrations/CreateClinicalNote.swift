import Fluent
import FluentSQL

struct CreateClinicalNote: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Check if table already exists (idempotent migration)
        if let sql = database as? SQLDatabase {
            let tables = try await sql.raw("SHOW TABLES LIKE 'clinical_notes'").all()
            guard tables.isEmpty else {
                return
            }
        }
        try await database.schema("clinical_notes")
            .id()
            .field("doctor_id", .uuid, .required, .references("doctors", "id"))
            .field("patient_id", .uuid, .required, .references("users", "id"))
            .field("appointment_id", .uuid, .required, .references("appointments", "id"))
            .field("diagnosis", .string, .required)
            .field("treatment", .string, .required)
            .field("notes", .string, .required)
            .field("follow_up_date", .string)
            .field("status", .string, .required)  // "draft", "completed"
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("clinical_notes").delete()
    }
}

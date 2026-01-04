import Fluent
import FluentSQL

struct CreateDoctor: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Check if table already exists (idempotent migration)
        if let sql = database as? SQLDatabase {
            let tables = try await sql.raw("SHOW TABLES LIKE 'doctors'").all()
            guard tables.isEmpty else {
                database.logger.info("Table 'doctors' already exists, skipping creation.")
                return
            }
        }
        
        try await database.schema("doctors")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("phone", .string, .required)
            .field("specialty", .string, .required)
            .field("status", .string, .required)
            
            // Missing fields added below:
            .field("license", .string)
            .field("experience", .int, .required)
            .field("education", .string)
            .field("bio", .string)
            .field("join_date", .string)
            .field("total_patients", .int, .required)
            .field("rating", .double, .required)
            
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("doctors").delete()
    }
}
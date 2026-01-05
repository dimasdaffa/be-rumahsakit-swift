import Fluent
import FluentSQL

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Check if table already exists (idempotent migration)
        if let sql = database as? SQLDatabase {
            let tables = try await sql.raw("SHOW TABLES LIKE 'users'").all()
            guard tables.isEmpty else {
                database.logger.info("Table 'users' already exists, skipping creation.")
                return
            }
        }
        // 1. Create the Enum type in MySQL first
        let roleSchema = try await database.enum("user_role")
            .case("admin")
            .case("doctor")
            .case("patient")
            .create()

        // 2. Create the Users table
        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("role", roleSchema, .required) // Use the Enum
            .field("created_at", .datetime)
            .unique(on: "email") // Email must be unique
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
        try await database.enum("user_role").delete()
    }
}
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
        // Check if enum exists first to avoid errors during fresh migration if not dropped cleanly
        try? await database.enum("user_role")
            .case("admin")
            .case("doctor")
            .case("patient")
            .create()

        // Re-fetch the enum to ensure we have the schema
        let roleSchema = try await database.enum("user_role").read()

        // 2. Create the Users table
        try await database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("role", roleSchema, .required)
            .field("phone", .string)
            .field("date_of_birth", .string)  // YYYY-MM-DD
            .field("gender", .string)  // "male", "female"
            .field("address", .string)
            .field("city", .string)
            .field("province", .string)
            .field("postal_code", .string)
            .field("emergency_contact", .string)
            .field("emergency_phone", .string)

            .field("created_at", .datetime)
            .field("updated_at", .datetime)  // Good practice to have updated_at
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
        try await database.enum("user_role").delete()
    }
}

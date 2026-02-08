import Fluent
import FluentSQL

struct CreateMessage: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Check if table already exists (idempotent migration)
        if let sql = database as? SQLDatabase {
            let tables = try await sql.raw("SHOW TABLES LIKE 'messages'").all()
            guard tables.isEmpty else {
                database.logger.info("Table 'messages' already exists, skipping creation.")
                return
            }
        }
        try await database.schema("messages")
            .id()
            .field("sender_id", .uuid, .required, .references("users", "id"))
            .field("receiver_id", .uuid, .required, .references("users", "id"))
            .field("content", .string, .required)
            .field("is_read", .bool, .required, .sql(.default(false)))
            .field("created_at", .datetime)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("messages").delete()
    }
}

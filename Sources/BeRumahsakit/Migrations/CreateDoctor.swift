import Fluent

struct CreateDoctor: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("doctors")
            .id()
            .field("name", .string, .required)
            .field("specialty", .string, .required)
            .field("phone", .string)
            .field("email", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("doctors").delete()
    }
}
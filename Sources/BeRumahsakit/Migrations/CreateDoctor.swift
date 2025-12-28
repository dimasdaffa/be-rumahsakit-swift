import Fluent

struct CreateDoctor: AsyncMigration {
    func prepare(on database: Database) async throws {
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
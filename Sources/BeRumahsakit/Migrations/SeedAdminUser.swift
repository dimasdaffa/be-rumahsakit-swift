import Fluent
import Vapor

struct SeedAdminUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        // 1. Check if an admin already exists to prevent duplicates
        let existingAdmin = try await User.query(on: database)
            .filter(\.$role == .admin)
            .first()
        
        guard existingAdmin == nil else {
            return // Admin already exists, do nothing
        }
        
        // 2. Create the Super Admin
        let passwordHash = try Bcrypt.hash("password123") // Default password
        
        let admin = User(
            name: "Super Admin",
            email: "admin@rumahsakit.com",
            passwordHash: passwordHash,
            role: .admin
        )
        
        // Optional: Add profile details if your User model requires them now
        admin.phone = "0000000000" 
        
        try await admin.save(on: database)
    }

    func revert(on database: Database) async throws {
        // Optional: Delete the admin on revert
        try await User.query(on: database)
            .filter(\.$email == "admin@rumahsakit.com")
            .delete()
    }
}
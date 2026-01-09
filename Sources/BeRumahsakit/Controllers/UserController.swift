import Vapor
import Fluent
import VaporToOpenAPI

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("api", "users")
        
        // 1. PUBLIC ROUTES (None)
        
        // 2. PROTECTED ROUTES (Any Logged-in User)
        // GET /api/users/me (Who am I?)
        users.get("me", use: getMe)
            .openAPI(summary: "Get current user profile")
            
        // PUT /api/users/me (Update my profile)
        users.put("me", use: updateMe)
            .openAPI(
                summary: "Update current user profile",
                body: .type(UpdateProfileRequest.self)
            )
            
        // 3. DOCTOR/ADMIN ROUTES
        // GET /api/patients (List all patients)
        users.get("patients", use: listPatients)
            .openAPI(summary: "List all patients (Doctor/Admin only)")
            
        // 4. ADMIN ROUTES
        // GET /api/users (List all system users)
        users.get(use: listAllUsers)
            .openAPI(summary: "List all users (Admin only)")
            
        // DELETE /api/users/:id
        users.delete(":id", use: deleteUser)
    }

    // 👤 GET /api/users/me
    @Sendable
    func getMe(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        return user.toPublic()
    }

    // ✏️ PUT /api/users/me
    @Sendable
    func updateMe(req: Request) async throws -> User.Public {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(UpdateProfileRequest.self)
        
        // Find fresh user from DB to ensure we modify the real record
        guard let dbUser = try await User.find(user.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        if let newName = input.name {
            dbUser.name = newName
        }
        if let newEmail = input.email {
            dbUser.email = newEmail
        }
        
        try await dbUser.save(on: req.db)
        return dbUser.toPublic()
    }

    // 🏥 GET /api/users/patients (Doctors/Admins Only)
    @Sendable
    func listPatients(req: Request) async throws -> [User.Public] {
        let user = try req.auth.require(User.self)
        
        // Guard: Only Doctors or Admins can see patient lists
        guard user.role == .doctor || user.role == .admin else {
            throw Abort(.forbidden, reason: "Only doctors can view patient lists")
        }
        
        // Fetch all users with role 'patient'
        let patients = try await User.query(on: req.db)
            .filter(\.$role == .patient)
            .all()
            
        return patients.map { $0.toPublic() }
    }

    // 👮‍♂️ GET /api/users (Admin Only)
    @Sendable
    func listAllUsers(req: Request) async throws -> [User.Public] {
        let user = try req.auth.require(User.self)
        
        guard user.role == .admin else {
            throw Abort(.forbidden)
        }
        
        let users = try await User.query(on: req.db).all()
        return users.map { $0.toPublic() }
    }
    
    // ❌ DELETE /api/users/:id (Admin Only)
    @Sendable
    func deleteUser(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard user.role == .admin else { throw Abort(.forbidden) }
        
        guard let userToDelete = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await userToDelete.delete(on: req.db)
        return .noContent
    }
}
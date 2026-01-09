import Vapor
import Fluent
import VaporToOpenAPI

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("api", "users")
        
        // ==========================
        // 1. PUBLIC ROUTES (None)
        // ==========================
        
        // ==========================
        // 2. PROTECTED ROUTES (Any Logged-in User)
        // ==========================
        
        // GET /api/users/me (Who am I?)
        users.get("me", use: getMe)
            .openAPI(summary: "Get current user profile")
            
        // PUT /api/users/me (Update my profile)
        users.put("me", use: updateMe)
            .openAPI(
                summary: "Update current user profile",
                body: .type(UpdateProfileRequest.self)
            )
            
        // ==========================
        // 3. DOCTOR & ADMIN ROUTES
        // ==========================
        
        // GET /api/users/patients (List all patients)
        users.get("patients", use: listPatients)
            .openAPI(summary: "List all patients (Doctor/Admin only)")

        // GET /api/users/patients/:id (Get specific patient details)
        users.get("patients", ":id", use: getPatientDetail)
            .openAPI(summary: "Get patient details (Doctor/Admin only)")
            
        // ==========================
        // 4. ADMIN ONLY ROUTES
        // ==========================
        
        // GET /api/users (List all system users)
        users.get(use: listAllUsers)
            .openAPI(summary: "List all users (Admin only)")
        
        // GET /api/users/:id (Get any user detail)
        users.get(":id", use: getUserDetail)
            .openAPI(summary: "Get specific user (Admin only)")

        // PUT /api/users/:id (Update any user)
        users.put(":id", use: updateUser)
            .openAPI(summary: "Update specific user (Admin only)")
            
        // DELETE /api/users/:id
        users.delete(":id", use: deleteUser)
    }

    // MARK: - Handlers

    // 👤 ME
    @Sendable
    func getMe(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        return UserResponse(user: user)
    }
    
    @Sendable
    func updateMe(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(UpdateProfileRequest.self)
        
        // Fetch fresh from DB
        guard let dbUser = try await User.find(user.id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        if let name = input.name { dbUser.name = name }
        if let email = input.email { dbUser.email = email }
        
        try await dbUser.save(on: req.db)
        return UserResponse(user: dbUser)
    }

    // 🏥 PATIENTS (Doctor/Admin)
    @Sendable
    func listPatients(req: Request) async throws -> [UserResponse] {
        let user = try req.auth.require(User.self)
        guard user.role == .doctor || user.role == .admin else {
            throw Abort(.forbidden, reason: "Only doctors can view patient lists")
        }
        
        let patients = try await User.query(on: req.db)
            .filter(\.$role == .patient)
            .all()
        return patients.map { UserResponse(user: $0) }
    }

    @Sendable
    func getPatientDetail(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        guard user.role == .doctor || user.role == .admin else { throw Abort(.forbidden) }
        
        guard let patient = try await User.find(req.parameters.get("id"), on: req.db),
              patient.role == .patient else {
            throw Abort(.notFound, reason: "Patient not found")
        }
        return UserResponse(user: patient)
    }

    // 👮‍♂️ ADMIN OPERATIONS
    @Sendable
    func listAllUsers(req: Request) async throws -> [UserResponse] {
        let user = try req.auth.require(User.self)
        guard user.role == .admin else { throw Abort(.forbidden) }
        
        let users = try await User.query(on: req.db).all()
        return users.map { UserResponse(user: $0) }
    }

    @Sendable
    func getUserDetail(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        guard user.role == .admin else { throw Abort(.forbidden) }

        guard let targetUser = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        return UserResponse(user: targetUser)
    }

    @Sendable
    func updateUser(req: Request) async throws -> UserResponse {
        let user = try req.auth.require(User.self)
        guard user.role == .admin else { throw Abort(.forbidden) }
        
        guard let targetUser = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let input = try req.content.decode(UpdateProfileRequest.self)
        if let name = input.name { targetUser.name = name }
        if let email = input.email { targetUser.email = email }
        
        try await targetUser.save(on: req.db)
        return UserResponse(user: targetUser)
    }
    
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
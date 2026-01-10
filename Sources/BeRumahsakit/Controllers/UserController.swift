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
        
        // Create a middleware group that restricts access to Admins only
        let adminRoutes = users.grouped(CheckRole(requiredRole: .admin))
        
        // POST /api/users (Create new user/admin) [NEW]
        adminRoutes.post(use: create)
            .openAPI(
                summary: "Create new user (Admin only)",
                body: .type(CreateUserRequest.self)
            )
        
        // GET /api/users (List all system users)
        adminRoutes.get(use: listAllUsers)
            .openAPI(summary: "List all users (Admin only)")
        
        // GET /api/users/:id (Get any user detail)
        adminRoutes.get(":id", use: getUserDetail)
            .openAPI(summary: "Get specific user (Admin only)")

        // PUT /api/users/:id (Update any user)
        adminRoutes.put(":id", use: updateUser)
            .openAPI(summary: "Update specific user (Admin only)")
            
        // DELETE /api/users/:id
        adminRoutes.delete(":id", use: deleteUser)
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
        
        // Basic Info
        if let name = input.name { dbUser.name = name }
        if let email = input.email { dbUser.email = email }
        
        // Profile Info
        if let phone = input.phone { dbUser.phone = phone }
        if let dob = input.dateOfBirth { dbUser.dateOfBirth = dob }
        if let gender = input.gender { dbUser.gender = gender }
        if let address = input.address { dbUser.address = address }
        if let city = input.city { dbUser.city = city }
        if let province = input.province { dbUser.province = province }
        if let postalCode = input.postalCode { dbUser.postalCode = postalCode }
        if let emergencyContact = input.emergencyContact { dbUser.emergencyContact = emergencyContact }
        if let emergencyPhone = input.emergencyPhone { dbUser.emergencyPhone = emergencyPhone }
        
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
    
    // [NEW] Create User Handler
    @Sendable
    func create(req: Request) async throws -> User.Public {
        // 1. Decode Input
        let input = try req.content.decode(CreateUserRequest.self)
        
        // 2. Validate Role
        guard let role = UserRole(rawValue: input.role) else {
            throw Abort(.badRequest, reason: "Invalid role. Use 'admin', 'doctor', or 'patient'")
        }
        
        // 3. Check Email Uniqueness
        if try await User.query(on: req.db).filter(\.$email == input.email).first() != nil {
            throw Abort(.conflict, reason: "Email already exists")
        }
        
        // 4. Create User
        let passwordHash = try Bcrypt.hash(input.password)
        
        let newUser = User(
            name: input.name,
            email: input.email,
            passwordHash: passwordHash,
            role: role
        )
        newUser.phone = input.phone
        
        try await newUser.save(on: req.db)
        
        return newUser.toPublic()
    }

    @Sendable
    func listAllUsers(req: Request) async throws -> [UserResponse] {
        // Auth check is handled by 'adminRoutes' group
        let users = try await User.query(on: req.db).all()
        return users.map { UserResponse(user: $0) }
    }

    @Sendable
    func getUserDetail(req: Request) async throws -> UserResponse {
        // Auth check is handled by 'adminRoutes' group
        guard let targetUser = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        return UserResponse(user: targetUser)
    }

    @Sendable
    func updateUser(req: Request) async throws -> UserResponse {
        // Auth check is handled by 'adminRoutes' group
        guard let targetUser = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let input = try req.content.decode(UpdateProfileRequest.self)
        if let name = input.name { targetUser.name = name }
        if let email = input.email { targetUser.email = email }
        if let phone = input.phone { targetUser.phone = phone }
        if let dob = input.dateOfBirth { targetUser.dateOfBirth = dob }
        if let gender = input.gender { targetUser.gender = gender }
        if let address = input.address { targetUser.address = address }
        if let city = input.city { targetUser.city = city }
        if let province = input.province { targetUser.province = province }
        if let postalCode = input.postalCode { targetUser.postalCode = postalCode }
        if let emergencyContact = input.emergencyContact { targetUser.emergencyContact = emergencyContact }
        if let emergencyPhone = input.emergencyPhone { targetUser.emergencyPhone = emergencyPhone }
        
        try await targetUser.save(on: req.db)
        return UserResponse(user: targetUser)
    }
    
    @Sendable
    func deleteUser(req: Request) async throws -> HTTPStatus {
        // Auth check is handled by 'adminRoutes' group
        guard let userToDelete = try await User.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await userToDelete.delete(on: req.db)
        return .noContent
    }
}
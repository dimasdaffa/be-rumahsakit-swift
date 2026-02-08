import Fluent
import JWT
import Vapor
import VaporToOpenAPI

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("api", "auth")

        // PUBLIC
        auth.post("register", use: register)
            .openAPI(
                summary: "Register new patient",
                body: .type(RegisterRequest.self)
            )

        auth.post("login", use: login)
            .openAPI(
                summary: "Login user",
                body: .type(LoginRequest.self)
            )

        // PROTECTED (Requires Token)
        // We use a separate group here because register/login are public
        let protected = auth.grouped(UserAuthenticator())
            .grouped(User.guardMiddleware())

        protected.post("change-password", use: changePassword)
            .openAPI(
                summary: "Change password",
                body: .type(ChangePasswordRequest.self)
            )

        // LOGOUT (New) ✅
        protected.post("logout", use: logout)
            .openAPI(summary: "Logout (Client should discard token)")
    }

    // 📝 REGISTER
    @Sendable
    func register(req: Request) async throws -> User.Public {
        let input = try req.content.decode(RegisterRequest.self)

        // 1. Restrict Doctor/Admin Registration
        // Only allow "patient" registration via public API.
        // Admins/Doctors must be created via the Admin Panel (DoctorController).
        let role = UserRole(rawValue: input.role) ?? .patient

        if role == .doctor || role == .admin {
            throw Abort(
                .forbidden, reason: "Doctors and Admins must be created by an Administrator.")
        }

        // 2. Check if email exists
        if (try await User.query(on: req.db).filter(\.$email == input.email).first()) != nil {
            throw Abort(.conflict, reason: "Email already exists")
        }

        // 3. Hash Password & Save
        let hashedPassword = try Bcrypt.hash(input.password)
        let user = User(
            name: input.name,
            email: input.email,
            passwordHash: hashedPassword,
            role: role
        )
        try await user.save(on: req.db)
        return user.toPublic()
    }

    // 🔑 LOGIN
    @Sendable
    func login(req: Request) async throws -> LoginResponse {
        // 1. Decode Input
        let input = try req.content.decode(LoginRequest.self)

        // 2. Find User
        guard
            let user = try await User.query(on: req.db)
                .filter(\.$email == input.email)
                .first()
        else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        // 3. Verify Password 🕵️‍♂️
        let isMatch = try Bcrypt.verify(input.password, created: user.passwordHash)
        if !isMatch {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        // 4. Generate JWT Token
        let payload = UserPayload(
            subject: .init(value: user.id!.uuidString),
            expiration: .init(value: .init(timeIntervalSinceNow: 60 * 60 * 24)),  // 24 Hours
            role: user.role.rawValue
        )

        let token = try req.jwt.sign(payload)

        return LoginResponse(token: token, user: user.toPublic())
    }

    // 🔐 CHANGE PASSWORD
    @Sendable
    func changePassword(req: Request) async throws -> SuccessResponse {
        // 1. Authenticate
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(ChangePasswordRequest.self)

        // 2. Verify Old Password
        let isMatch = try Bcrypt.verify(input.currentPassword, created: user.passwordHash)
        if !isMatch {
            throw Abort(.unauthorized, reason: "Current password is incorrect")
        }

        // 3. Hash New Password
        let newHash = try Bcrypt.hash(input.newPassword)

        // 4. Update DB
        guard let dbUser = try await User.find(user.id, on: req.db) else {
            throw Abort(.notFound)
        }
        dbUser.passwordHash = newHash
        try await dbUser.save(on: req.db)

        return SuccessResponse(success: true, message: "Password updated successfully")
    }

    // POST /api/auth/logout
    @Sendable
    func logout(req: Request) async throws -> HTTPStatus {
        // We require a valid token to "logout"
        let _ = try req.auth.require(User.self)

        // Since we use stateless JWTs, we just return 200 OK.
        // The Client App MUST delete the token from its storage (Keychain/UserDefaults).
        return .ok
    }
}

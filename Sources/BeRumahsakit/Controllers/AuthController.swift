import Vapor
import Fluent
import JWT
import VaporToOpenAPI

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("api", "auth")
        
        // POST /api/auth/register
        auth.post("register", use: register)
            .openAPI(
                summary: "Register new user",
                body: .type(RegisterRequest.self)
            )
        
        // POST /api/auth/login
        auth.post("login", use: login)
            .openAPI(
                summary: "Login and get Token",
                body: .type(LoginRequest.self)
            )
    }

    // 📝 REGISTER
    @Sendable
    func register(req: Request) async throws -> User.Public {
        // 1. Validate Input
        let input = try req.content.decode(RegisterRequest.self)
        
        // 2. Check if email exists
        if let _ = try await User.query(on: req.db).filter(\.$email == input.email).first() {
            throw Abort(.conflict, reason: "Email already exists")
        }
        
        // 3. Hash Password 🔒
        let hashedPassword = try Bcrypt.hash(input.password)
        
        // 4. Create & Save User
        // Note: We force-unwrap UserRole(rawValue:) for simplicity, but you should handle invalid roles safer in production
        let role = UserRole(rawValue: input.role) ?? .patient
        
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
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == input.email)
            .first() else {
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
            expiration: .init(value: .init(timeIntervalSinceNow: 60 * 60 * 24)), // 24 Hours
            role: user.role.rawValue
        )
        
        let token = try req.jwt.sign(payload)
        
        return LoginResponse(token: token, user: user.toPublic())
    }
}
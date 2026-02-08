import Vapor

struct CheckRole: AsyncMiddleware {
    let requiredRole: UserRole

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // 1. Get the logged-in user (AuthMiddleware must run before this!)
        let user = try request.auth.require(User.self)
        
        // 2. Check if their role matches the requirement
        guard user.role == requiredRole else {
            throw Abort(.forbidden, reason: "⛔️ Access Denied: You must be an \(requiredRole.rawValue) to do this.")
        }
        
        // 3. Allow access
        return try await next.respond(to: request)
    }
}
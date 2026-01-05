import Vapor
import JWT

struct UserAuthenticator: AsyncJWTAuthenticator {
    // We use the Payload struct you created in AuthDTOs.swift
    typealias Payload = UserPayload 

    func authenticate(jwt: Payload, for request: Request) async throws {
        // 1. Vapor has already verified the signature at this point.
        
        // 2. (Optional) Check if user still exists in DB
        // This prevents deleted users from using old tokens.
        guard let uuid = UUID(uuidString: jwt.subject.value) else {
            throw Abort(.unauthorized, reason: "Invalid User ID in Token")
        }

        guard let user = try await User.find(uuid, on: request.db) else {
            throw Abort(.unauthorized, reason: "User not found")
        }

        // 3. Log them in for this request! 🔓
        request.auth.login(user)
    }
}
import Vapor
import JWT

// 1. What the user sends to Register
struct RegisterRequest: Content {
    var name: String
    var email: String
    var password: String
    var role: String // "admin", "doctor", or "patient"
}

// 2. What the user sends to Login
struct LoginRequest: Content {
    var email: String
    var password: String
}

// 3. What we return after successful Login
struct LoginResponse: Content {
    var token: String
    var user: User.Public
}

// 4. The Data inside the JWT Token (Payload)
struct UserPayload: JWTPayload {
    var subject: SubjectClaim // The User ID
    var expiration: ExpirationClaim
    var role: String

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}
import JWT
import Vapor

// 1. What the user sends to Register
struct RegisterRequest: Content {
    var name: String
    var email: String
    var password: String
    var role: String  // "admin", "doctor", or "patient"
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
    var subject: SubjectClaim  // The User ID
    var expiration: ExpirationClaim
    var role: String

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}

struct CreateAppointmentRequest: Content {
    var doctorId: UUID
    var date: String
    var time: String
    var reason: String
    var complaints: String?
}

struct VitalSignsDTO: Content {
    var bloodPressure: String?
    var heartRate: String?
    var temperature: String?
    var weight: String?
}

struct CreateMedicalRecordRequest: Content {
    var appointmentId: UUID
    var diagnosis: String
    var symptoms: String
    var treatment: String
    var prescription: String?
    var notes: String?
    var followUpRequired: Bool
    var followUpDate: String?
    var vitalSigns: VitalSignsDTO?
}

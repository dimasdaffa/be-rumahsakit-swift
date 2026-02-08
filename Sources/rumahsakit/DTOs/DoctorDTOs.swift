import Vapor

// 1. INPUT DTO (For Admins creating doctors)
struct CreateDoctorInput: Content {
    var name: String
    var email: String
    var password: String? 
    var phone: String
    var specialty: String
    var status: String
    var license: String?
    var experience: Int
    var education: String?
    var bio: String?
    var joinDate: String?
    var totalPatients: Int
    var rating: Double
}

// 2. PUBLIC RESPONSE DTO (Safe for Patients)
// This excludes 'passwordHash', 'user' object, and private fields.
struct DoctorPublicResponse: Content {
    var id: UUID
    var name: String
    var specialty: String
    var status: String
    var experience: Int
    var rating: Double
    var bio: String?
    var education: String?
    var license: String?
}

// 3. DOCTOR SELF-UPDATE DTO
// Allows doctors to update their own profile details
struct UpdateDoctorMyProfileRequest: Content {
    var phone: String?
    var specialty: String?
    var status: String? // "active", "busy", "offline"
    var education: String?
    var bio: String?
    var experience: Int?
}
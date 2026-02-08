import Vapor

// Updated to match "PUT /api/users/me" Spec
struct UpdateProfileRequest: Content {
    var name: String?
    var email: String? 
    var phone: String?
    var dateOfBirth: String?
    var gender: String?
    var address: String?
    var city: String?
    var province: String?
    var postalCode: String?
    var emergencyContact: String?
    var emergencyPhone: String?
}

struct ChangePasswordRequest: Content {
    var currentPassword: String
    var newPassword: String
}

struct SuccessResponse: Content {
    var success: Bool
    var message: String
}

// Full User Response for "GET /api/users/me"
struct UserResponse: Content {
    var id: UUID
    var name: String
    var email: String
    var role: String
    
    // New Fields
    var phone: String?
    var dateOfBirth: String?
    var gender: String?
    var address: String?
    var city: String?
    var province: String?
    var postalCode: String?
    var emergencyContact: String?
    var emergencyPhone: String?
    
    var createdAt: Date?
    var updatedAt: Date?
    
    init(user: User) {
        self.id = user.id!
        self.name = user.name
        self.email = user.email
        self.role = user.role.rawValue
        self.phone = user.phone
        self.dateOfBirth = user.dateOfBirth
        self.gender = user.gender
        self.address = user.address
        self.city = user.city
        self.province = user.province
        self.postalCode = user.postalCode
        self.emergencyContact = user.emergencyContact
        self.emergencyPhone = user.emergencyPhone
        
        self.createdAt = user.createdAt
        self.updatedAt = user.updatedAt
    }
}

struct CreateUserRequest: Content {
    var name: String
    var email: String
    var password: String
    var role: String // "admin", "doctor", "patient"
    var phone: String?
}
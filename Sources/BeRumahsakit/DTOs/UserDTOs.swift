import Vapor

// What we send to update a profile
struct UpdateProfileRequest: Content {
    var name: String?
    var email: String?
}

// What we send to change a password
struct ChangePasswordRequest: Content {
    var oldPassword: String
    var newPassword: String
}

// A generic success message response
struct SuccessResponse: Content {
    var success: Bool
    var message: String
}

// Standard User Response (Safe output)
struct UserResponse: Content {
    var id: UUID
    var name: String
    var email: String
    var role: String
    var createdAt: Date?
    
    init(user: User) {
        self.id = user.id!
        self.name = user.name
        self.email = user.email
        self.role = user.role.rawValue
        self.createdAt = user.createdAt
    }
}
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
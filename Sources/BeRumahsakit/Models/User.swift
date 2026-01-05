import Vapor
import Fluent

// Enums for Role-Based Access Control (RBAC)
enum UserRole: String, Codable {
    case admin
    case doctor
    case patient
}

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Enum(key: "role")
    var role: UserRole

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String, role: UserRole) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.role = role
    }
    
    // We hide the password hash when returning JSON
    func toPublic() -> Public {
        Public(id: id, name: name, email: email, role: role, createdAt: createdAt)
    }
    
    struct Public: Content {
        var id: UUID?
        var name: String
        var email: String
        var role: UserRole
        var createdAt: Date?
    }
}
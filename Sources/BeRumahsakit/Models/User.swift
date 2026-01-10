import Vapor
import Fluent

// Enums for Role-Based Access Control (RBAC)
enum UserRole: String, Codable {
    case admin
    case doctor
    case patient
}

final class User: Model, Content, @unchecked Sendable, Authenticatable {
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

    @OptionalField(key: "phone")
    var phone: String?

    @OptionalField(key: "date_of_birth")
    var dateOfBirth: String?

    @OptionalField(key: "gender")
    var gender: String?

    @OptionalField(key: "address")
    var address: String?

    @OptionalField(key: "city")
    var city: String?

    @OptionalField(key: "province")
    var province: String?

    @OptionalField(key: "postal_code")
    var postalCode: String?

    @OptionalField(key: "emergency_contact")
    var emergencyContact: String?

    @OptionalField(key: "emergency_phone")
    var emergencyPhone: String?
    // --------------------------

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, name: String, email: String, passwordHash: String, role: UserRole) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.role = role
    }
    
    // Updated Public DTO
    func toPublic() -> Public {
        Public(
            id: id, 
            name: name, 
            email: email, 
            role: role, 
            createdAt: createdAt,
            phone: phone,
            address: address
        )
    }
    
    struct Public: Content {
        var id: UUID?
        var name: String
        var email: String
        var role: UserRole
        var createdAt: Date?
        var phone: String?
        var address: String?
    }
}
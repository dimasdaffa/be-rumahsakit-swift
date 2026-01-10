import Vapor
import Fluent

final class Doctor: Model, Content {
    static let schema = "doctors"
    
    @ID(key: .id)
    var id: UUID?
    
    // 🔗 Link to the Login User
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "phone")
    var phone: String
    
    @Field(key: "specialty")
    var specialty: String
    
    @Field(key: "status")
    var status: String
    
    @OptionalField(key: "license")
    var license: String?
    
    @Field(key: "experience")
    var experience: Int
    
    @OptionalField(key: "education")
    var education: String?
    
    @OptionalField(key: "bio")
    var bio: String?
    
    @OptionalField(key: "join_date")
    var joinDate: String?
    
    @Field(key: "total_patients")
    var totalPatients: Int
    
    @Field(key: "rating")
    var rating: Double

    init() { }

    init(id: UUID? = nil, userId: UUID, name: String, email: String, phone: String, specialty: String, status: String, license: String? = nil, experience: Int = 0, education: String? = nil, bio: String? = nil, joinDate: String? = nil, totalPatients: Int = 0, rating: Double = 0.0) {
        self.id = id
        self.$user.id = userId // Set the User ID
        self.name = name
        self.email = email
        self.phone = phone
        self.specialty = specialty
        self.status = status
        self.license = license
        self.experience = experience
        self.education = education
        self.bio = bio
        self.joinDate = joinDate
        self.totalPatients = totalPatients
        self.rating = rating
    }
}
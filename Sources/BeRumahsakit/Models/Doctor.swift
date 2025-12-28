import Vapor
import Fluent

final class Doctor: Model, Content {
    // Name of the table in MySQL
    static let schema = "doctors"
    
    @ID(key: .id)
    var id: UUID?
    
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
    
    // Optional Fields (matches your frontend form)
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

    // Required by Fluent
    init() { }

    // Init for you to use in code
    init(id: UUID? = nil, name: String, email: String, phone: String, specialty: String, status: String, license: String? = nil, experience: Int = 0, education: String? = nil, bio: String? = nil, joinDate: String? = nil, totalPatients: Int = 0, rating: Double = 0.0) {
        self.id = id
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
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
    var avatarURL: String?
    var reviewCount: Int?
    var practice: DoctorPractice?
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
    var userId: UUID
    var totalPatients: Int
    var avatarURL: String?
    var reviewCount: Int?
    var practice: DoctorPractice?
    var isFavorite: Bool?
    var nextAvailable: AppointmentSlot?

    init(_ doctor: Doctor, isFavorite: Bool? = nil, nextAvailable: AppointmentSlot? = nil) {
        id = doctor.id!
        name = doctor.name
        specialty = doctor.specialty
        status = doctor.status
        experience = doctor.experience
        rating = doctor.rating
        bio = doctor.bio
        education = doctor.education
        license = doctor.license
        userId = doctor.$user.id
        totalPatients = doctor.totalPatients
        avatarURL = doctor.avatarURL
        reviewCount = doctor.reviewCount
        practice = doctor.practice
        self.isFavorite = isFavorite
        self.nextAvailable = nextAvailable
    }
}

struct DoctorPractice: Content {
    let name: String
    let address: String?
    let room: String?
    let fee: Int?
    let currency: String?
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
    var avatarURL: String?
    var practice: DoctorPractice?
}
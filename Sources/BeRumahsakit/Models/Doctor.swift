import Vapor

struct Doctor: Content {
    var id: String?
    var name: String
    var email: String
    var phone: String
    var specialty: String
    var status: String
    var license: String?
    var experience: Int?
    var education: String?
    var bio: String?
    var joinDate: String?
    var totalPatients: Int?
    var rating: Double?
}
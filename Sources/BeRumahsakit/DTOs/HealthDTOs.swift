import Vapor

struct CreateHealthUpdateRequest: Content {
    var date: String
    var weight: Double?
    var height: Double?
    var bloodPressure: String?
    var bloodSugar: Double?
    var heartRate: Int?
    var sleepHours: Double?
    var mood: String?
    var notes: String?
    var patientId: UUID? 
}
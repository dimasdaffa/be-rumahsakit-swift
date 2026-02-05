import Vapor
import Fluent

final class HealthUpdate: Model, Content {
    static let schema = "health_updates"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "patient_id")
    var patient: User

    @Field(key: "date")
    var date: String

    @OptionalField(key: "weight")
    var weight: Double?

    @OptionalField(key: "height")
    var height: Double?

    @OptionalField(key: "blood_pressure")
    var bloodPressure: String?

    @OptionalField(key: "blood_sugar")
    var bloodSugar: Double?

    @OptionalField(key: "heart_rate")
    var heartRate: Int?
    
    @OptionalField(key: "sleep_hours")
    var sleepHours: Double?

    @OptionalField(key: "mood")
    var mood: String?

    @OptionalField(key: "notes")
    var notes: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil, patientId: UUID, date: String, weight: Double?, height: Double?, bloodPressure: String?, bloodSugar: Double?, heartRate: Int?, sleepHours: Double?, mood: String?, notes: String?) {
        self.id = id
        self.$patient.id = patientId
        self.date = date
        self.weight = weight
        self.height = height
        self.bloodPressure = bloodPressure
        self.bloodSugar = bloodSugar
        self.heartRate = heartRate
        self.sleepHours = sleepHours
        self.mood = mood
        self.notes = notes
    }
}
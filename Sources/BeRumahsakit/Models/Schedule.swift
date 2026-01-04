import Vapor
import Fluent

final class Schedule: Model, Content {
    static let schema = "schedules"

    @ID(key: .id)
    var id: UUID?

    // 🔗 RELATIONSHIP: Links this schedule to a Doctor
    @Parent(key: "doctor_id")
    var doctor: Doctor

    @Field(key: "date")
    var date: String // Format: "2024-01-30"

    @Field(key: "time")
    var time: String // Format: "09:00"

    @Field(key: "is_available")
    var isAvailable: Bool

    init() { }

    init(id: UUID? = nil, doctorId: Doctor.IDValue, date: String, time: String, isAvailable: Bool = true) {
        self.id = id
        self.$doctor.id = doctorId // Set the foreign key
        self.date = date
        self.time = time
        self.isAvailable = isAvailable
    }
}
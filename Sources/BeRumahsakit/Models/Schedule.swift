import Vapor
import Fluent

final class Schedule: Model, Content {
    static let schema = "schedules"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "doctor_id")
    var doctor: Doctor

    @Field(key: "day_of_week")
    var dayOfWeek: String

    @Field(key: "start_time")
    var startTime: String

    @Field(key: "end_time")
    var endTime: String

    @Field(key: "is_available")
    var isAvailable: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil, doctorId: UUID, dayOfWeek: String, startTime: String, endTime: String, isAvailable: Bool = true) {
        self.id = id
        self.$doctor.id = doctorId
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.isAvailable = isAvailable
    }
}
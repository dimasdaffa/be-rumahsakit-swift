import Fluent
import Vapor

final class MedicationIntake: Model {
    static let schema = "medication_intakes"

    @ID(key: .id) var id: UUID?
    @Field(key: "record_id") var recordId: UUID
    @Field(key: "medication_id") var medicationId: UUID
    @Field(key: "date") var date: String
    @Field(key: "time") var time: String
    @Timestamp(key: "taken_at", on: .create) var takenAt: Date?

    init() {}
}

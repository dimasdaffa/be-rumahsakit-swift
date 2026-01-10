import Vapor
import Fluent

final class Appointment: Model, Content {
    static let schema = "appointments"

    @ID(key: .id)
    var id: UUID?

    // 🔗 LINK 1: The Patient (User)
    @Parent(key: "patient_id")
    var patient: User

    // 🔗 LINK 2: The Doctor
    @Parent(key: "doctor_id")
    var doctor: Doctor

    @Field(key: "date")
    var date: String // "2024-06-01"

    @Field(key: "time")
    var time: String // "09:00"

    @Field(key: "reason")
    var reason: String // "Sakit kepala"

    @OptionalField(key: "complaints")
    var complaints: String?

    @Field(key: "status")
    var status: String // "pending", "approved", "rejected", "completed"

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil, patientId: User.IDValue, doctorId: Doctor.IDValue, date: String, time: String, reason: String, complaints: String? = nil, status: String = "pending") {
        self.id = id
        self.$patient.id = patientId
        self.$doctor.id = doctorId
        self.date = date
        self.time = time
        self.reason = reason
        self.complaints = complaints
        self.status = status
    }
}
import Fluent
import Vapor

final class PatientNotification: Model, Content {
    static let schema = "patient_notifications"

    @ID(key: .id) var id: UUID?
    @Field(key: "patient_id") var patientId: UUID
    @Field(key: "appointment_id") var appointmentId: UUID
    @Field(key: "type") var type: String
    @OptionalField(key: "read_at") var readAt: Date?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}

    static func appointmentChanged(_ appointment: Appointment, type: String, on database: any Database) async throws {
        let patient = try await User.find(appointment.$patient.id, on: database)
        guard patient?.appointmentNotifications != false else { return }
        let notification = PatientNotification()
        notification.patientId = appointment.$patient.id
        notification.appointmentId = try appointment.requireID()
        notification.type = type
        try await notification.create(on: database)
    }
}

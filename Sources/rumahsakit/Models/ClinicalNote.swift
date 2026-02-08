import Vapor
import Fluent

final class ClinicalNote: Model, Content {
    static let schema = "clinical_notes"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "doctor_id")
    var doctor: Doctor

    @Parent(key: "patient_id")
    var patient: User

    @Parent(key: "appointment_id")
    var appointment: Appointment

    @Field(key: "diagnosis")
    var diagnosis: String

    @Field(key: "treatment")
    var treatment: String

    @Field(key: "notes")
    var notes: String

    @OptionalField(key: "follow_up_date")
    var followUpDate: String?

    @Field(key: "status")
    var status: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() { }

    init(id: UUID? = nil, doctorId: UUID, patientId: UUID, appointmentId: UUID, diagnosis: String, treatment: String, notes: String, followUpDate: String?, status: String) {
        self.id = id
        self.$doctor.id = doctorId
        self.$patient.id = patientId
        self.$appointment.id = appointmentId
        self.diagnosis = diagnosis
        self.treatment = treatment
        self.notes = notes
        self.followUpDate = followUpDate
        self.status = status
    }
}
import Vapor
import Fluent

final class MedicalRecord: Model, Content {
    static let schema = "medical_records"

    @ID(key: .id)
    var id: UUID?

    // 🔗 LINK: Belongs to an Appointment
    // (This automatically links it to the Doctor & Patient of that appointment)
    @Parent(key: "appointment_id")
    var appointment: Appointment

    // We store Patient ID directly too, for faster searching later
    @Parent(key: "patient_id")
    var patient: User

    @Field(key: "diagnosis")
    var diagnosis: String

    @Field(key: "symptoms")
    var symptoms: String

    @Field(key: "treatment")
    var treatment: String

    @OptionalField(key: "prescription")
    var prescription: String?

    @OptionalField(key: "notes")
    var notes: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil, appointmentId: Appointment.IDValue, patientId: User.IDValue, diagnosis: String, symptoms: String, treatment: String, prescription: String? = nil, notes: String? = nil) {
        self.id = id
        self.$appointment.id = appointmentId
        self.$patient.id = patientId
        self.diagnosis = diagnosis
        self.symptoms = symptoms
        self.treatment = treatment
        self.prescription = prescription
        self.notes = notes
    }
}
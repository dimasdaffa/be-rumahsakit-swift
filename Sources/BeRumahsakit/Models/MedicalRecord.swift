import Fluent
import Vapor

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

    @Field(key: "follow_up_required")
    var followUpRequired: Bool

    @OptionalField(key: "follow_up_date")
    var followUpDate: String?

    // Vitals
    @OptionalField(key: "vital_blood_pressure")
    var vitalBloodPressure: String?

    @OptionalField(key: "vital_heart_rate")
    var vitalHeartRate: String?

    @OptionalField(key: "vital_temperature")
    var vitalTemperature: String?

    @OptionalField(key: "vital_weight")
    var vitalWeight: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() {}

    init(
        id: UUID? = nil, 
        appointmentId: Appointment.IDValue, 
        patientId: User.IDValue, 
        diagnosis: String, 
        symptoms: String, 
        treatment: String, 
        prescription: String? = nil, 
        notes: String? = nil,
        followUpRequired: Bool = false,
        followUpDate: String? = nil,
        vitalBloodPressure: String? = nil,
        vitalHeartRate: String? = nil,
        vitalTemperature: String? = nil,
        vitalWeight: String? = nil
    ) {
        self.id = id
        self.$appointment.id = appointmentId
        self.$patient.id = patientId
        self.diagnosis = diagnosis
        self.symptoms = symptoms
        self.treatment = treatment
        self.prescription = prescription
        self.notes = notes
        self.followUpRequired = followUpRequired
        self.followUpDate = followUpDate
        self.vitalBloodPressure = vitalBloodPressure
        self.vitalHeartRate = vitalHeartRate
        self.vitalTemperature = vitalTemperature
        self.vitalWeight = vitalWeight
    }
}

import Vapor

struct CreateClinicalNoteRequest: Content {
    var patientId: UUID
    var appointmentId: UUID
    var diagnosis: String
    var treatment: String
    var notes: String
    var followUp: String?
    var status: String // "draft" or "completed"
}

struct UpdateClinicalNoteRequest: Content {
    var diagnosis: String?
    var treatment: String?
    var notes: String?
    var followUp: String?
    var status: String?
}
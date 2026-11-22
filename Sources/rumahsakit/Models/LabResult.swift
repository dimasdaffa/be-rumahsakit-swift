import Fluent
import Vapor

final class LabResult: Model {
    static let schema = "lab_results"

    @ID(key: .id) var id: UUID?
    @Field(key: "patient_id") var patientId: UUID
    @Field(key: "title") var title: String
    @Field(key: "laboratory") var laboratory: String
    @Field(key: "collected_at") var collectedAt: Date
    @OptionalField(key: "alert") var alert: String?
    @Field(key: "panels") var panels: [LabPanel]
    @OptionalField(key: "doctor_note") var doctorNote: String?
    @OptionalField(key: "author_name") var authorName: String?
    @OptionalField(key: "author_specialty") var authorSpecialty: String?
    @OptionalField(key: "pdf_document_id") var pdfDocumentId: UUID?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?

    init() {}
}

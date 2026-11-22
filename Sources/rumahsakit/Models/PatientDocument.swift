import Fluent
import FluentSQL
import Vapor

final class PatientDocument: Model {
    static let schema = "patient_documents"

    @ID(key: .id) var id: UUID?
    @Field(key: "patient_id") var patientId: UUID
    @OptionalField(key: "medical_record_id") var medicalRecordId: UUID?
    @Field(key: "name") var name: String
    @OptionalField(key: "card_number") var cardNumber: String?
    @Enum(key: "category") var category: DocumentCategory
    @Field(key: "media_type") var mediaType: String
    @Field(key: "size") var size: Int
    // shortcut: keep the bounded file with its metadata for atomic writes in the demo, move large workloads to private object storage.
    @OptionalField(key: "data") var data: String?
    @OptionalField(key: "deleted_at") var deletedAt: Date?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Timestamp(key: "updated_at", on: .update) var updatedAt: Date?

    init() {}

    static func summaryQuery(on db: any Database) -> QueryBuilder<PatientDocument> {
        query(on: db).field(\.$id).field(\.$patientId).field(\.$medicalRecordId)
            .field(\.$name).field(\.$cardNumber).field(\.$category).field(\.$mediaType)
            .field(\.$size).field(\.$deletedAt).field(\.$createdAt).field(\.$updatedAt)
    }

    static func lock(_ id: UUID, on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { throw Abort(.internalServerError) }
        guard try await sql.raw("SELECT id FROM patient_documents WHERE id = \(bind: id) FOR UPDATE").first() != nil else {
            throw Abort(.notFound)
        }
    }

    func fileResponse() throws -> Response {
        guard deletedAt == nil, let data, let bytes = Data(base64Encoded: data) else { throw Abort(.notFound) }
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentType, value: mediaType)
        let suffixes = [
            "application/pdf": "pdf", "image/jpeg": "jpg", "image/png": "png",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document": "docx"
        ]
        let suffix = suffixes[mediaType] ?? "bin"
        headers.replaceOrAdd(name: .contentDisposition, value: "attachment; filename=\"document.\(suffix)\"")
        headers.replaceOrAdd(name: .cacheControl, value: "private, no-store")
        return Response(status: .ok, headers: headers, body: .init(data: bytes))
    }
}

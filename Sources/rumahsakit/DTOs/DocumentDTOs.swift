import Vapor

enum DocumentCategory: String, Codable, Sendable, CaseIterable {
    case bpjs, insurance, familyCard, idCard, other, clinicalAttachment
}

struct DocumentInput: Content {
    let name: String
    let cardNumber: String?
    let category: DocumentCategory
    let file: File?
    let patientId: UUID?
    let medicalRecordId: UUID?
}

struct DocumentResponse: Content {
    let id: UUID
    let medicalRecordId: UUID?
    let name: String
    let cardNumber: String?
    let category: DocumentCategory
    let mediaType: String
    let size: Int
    let createdAt: Date?
    let updatedAt: Date?
    let deletedAt: Date?
    let downloadPath: String?

    init(_ document: PatientDocument) throws {
        id = try document.requireID()
        medicalRecordId = document.medicalRecordId
        name = document.name
        cardNumber = document.cardNumber
        category = document.category
        mediaType = document.mediaType
        size = document.size
        createdAt = document.createdAt
        updatedAt = document.updatedAt
        deletedAt = document.deletedAt
        downloadPath = deletedAt == nil ? "/api/documents/\(id)/download" : nil
    }
}

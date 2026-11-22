import Fluent
import Vapor
import VaporToOpenAPI

struct DocumentController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let documents = routes.grouped("api", "documents")
        documents.get(use: index).openAPI(summary: "List patient documents")
        documents.on(.POST, body: .collect(maxSize: "6mb"), use: create).openAPI(summary: "Upload a private patient document")
        documents.get("history", use: history).openAPI(summary: "List document history, including deleted documents")
        documents.on(.PUT, ":id", body: .collect(maxSize: "6mb"), use: update).openAPI(summary: "Update document metadata or replace the file")
        documents.get(":id", "download", use: download).openAPI(summary: "Download a private patient document")
        documents.delete(":id", use: delete).openAPI(summary: "Remove the file and retain document history")
        routes.get("api", "medical-records", ":id", "documents", use: recordDocuments)
            .openAPI(summary: "List private attachments for a medical record")
    }

    @Sendable
    func index(req: Request) async throws -> [DocumentResponse] {
        try await list(req, includeDeleted: false)
    }

    @Sendable
    func history(req: Request) async throws -> [DocumentResponse] {
        try await list(req, includeDeleted: true)
    }

    private func list(_ req: Request, includeDeleted: Bool) async throws -> [DocumentResponse] {
        let user = try req.auth.require(User.self)
        let patientId = try req.query[UUID.self, at: "patientId"] ?? user.requireID()
        try await PatientAccess.require(user, patientId: patientId, on: req.db)
        let query = PatientDocument.summaryQuery(on: req.db).filter(\.$patientId == patientId)
        if !includeDeleted { query.filter(\.$deletedAt == nil) }
        if user.role == .doctor { query.filter(\.$category == .clinicalAttachment) }
        return try await query.sort(\.$updatedAt, .descending).all().map(DocumentResponse.init)
    }

    @Sendable
    func create(req: Request) async throws -> DocumentResponse {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(DocumentInput.self, using: FormDataDecoder())
        guard let file = input.file else { throw Abort(.badRequest, reason: "File is required") }
        let patientId = try input.patientId ?? user.requireID()
        try await PatientAccess.require(user, patientId: patientId, on: req.db)
        guard try await User.find(patientId, on: req.db)?.role == .patient else { throw Abort(.notFound) }
        if user.role == .doctor && input.category != .clinicalAttachment { throw Abort(.forbidden) }
        if input.medicalRecordId != nil || input.category == .clinicalAttachment {
            guard user.role != .patient, input.category == .clinicalAttachment else { throw Abort(.forbidden) }
            if let recordId = input.medicalRecordId {
                guard let record = try await MedicalRecord.find(recordId, on: req.db), record.$patient.id == patientId else {
                    throw Abort(.notFound)
                }
                try await PatientAccess.requireRecord(user, record: record, on: req.db)
            }
        }
        let document = PatientDocument()
        document.patientId = patientId
        document.medicalRecordId = input.medicalRecordId
        try applyMetadata(input, to: document)
        try applyFile(file, to: document)
        try await document.create(on: req.db)
        return try DocumentResponse(document)
    }

    @Sendable
    func update(req: Request) async throws -> DocumentResponse {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(DocumentInput.self)
        let id = try req.parameters.require("id", as: UUID.self)
        let document = try await mutate(id, user: user, on: req.db) { document in
            guard input.patientId == nil, input.medicalRecordId == nil,
                  (document.category == .clinicalAttachment) == (input.category == .clinicalAttachment) else {
                throw Abort(.badRequest)
            }
            try applyMetadata(input, to: document)
            if let file = input.file { try applyFile(file, to: document) }
        }
        return try DocumentResponse(document)
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require("id", as: UUID.self)
        _ = try await mutate(id, user: user, on: req.db) { document in
            document.data = nil
            document.deletedAt = Date()
        }
        return .noContent
    }

    @Sendable
    func download(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require("id", as: UUID.self)
        guard let document = try await PatientDocument.find(id, on: req.db) else { throw Abort(.notFound) }
        try await requireDocumentAccess(user, document: document, on: req.db)
        return try document.fileResponse()
    }

    @Sendable
    func recordDocuments(req: Request) async throws -> [DocumentResponse] {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require("id", as: UUID.self)
        guard let record = try await MedicalRecord.find(id, on: req.db) else { throw Abort(.notFound) }
        try await PatientAccess.requireRecord(user, record: record, on: req.db)
        return try await PatientDocument.summaryQuery(on: req.db)
            .filter(\.$medicalRecordId == id).filter(\.$deletedAt == nil)
            .sort(\.$createdAt, .descending).all().map(DocumentResponse.init)
    }

    private func mutate(
        _ id: UUID, user: User, on db: any Database, _ change: @escaping @Sendable (PatientDocument) throws -> Void
    ) async throws -> PatientDocument {
        try await db.transaction { database in
            try await PatientDocument.lock(id, on: database)
            guard let document = try await PatientDocument.find(id, on: database), document.deletedAt == nil else {
                throw Abort(.notFound)
            }
            if document.category == .clinicalAttachment && user.role == .patient { throw Abort(.forbidden) }
            try await requireDocumentAccess(user, document: document, on: database)
            let previousData = document.data
            try change(document)
            if document.deletedAt != nil || document.data != previousData {
                guard try await LabResult.query(on: database).filter(\.$pdfDocumentId == id).first() == nil else {
                    throw Abort(.conflict, reason: "This document is the PDF for a published lab result")
                }
            }
            try await document.update(on: database)
            return document
        }
    }

    private func requireDocumentAccess(_ user: User, document: PatientDocument, on db: any Database) async throws {
        if user.role == .doctor && document.category != .clinicalAttachment { throw Abort(.forbidden) }
        try await PatientAccess.require(user, patientId: document.patientId, on: db)
    }

    private func applyMetadata(_ input: DocumentInput, to document: PatientDocument) throws {
        let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.utf8.count <= 255, (input.cardNumber?.utf8.count ?? 0) <= 255 else { throw Abort(.badRequest) }
        document.name = name
        document.cardNumber = input.cardNumber
        document.category = input.category
    }

    private func applyFile(_ file: File, to document: PatientDocument) throws {
        let bytes = Data(file.data.readableBytesView)
        guard bytes.count <= 5 * 1024 * 1024 else { throw Abort(.payloadTooLarge) }
        let clinicalDocx = document.category == .clinicalAttachment && file.filename.lowercased().hasSuffix(".docx") &&
            bytes.starts(with: [0x50, 0x4B, 0x03, 0x04]) && bytes.range(of: Data("[Content_Types].xml".utf8)) != nil &&
            bytes.range(of: Data("word/document.xml".utf8)) != nil
        guard let type = Self.mediaType(bytes) ?? (clinicalDocx ? "application/vnd.openxmlformats-officedocument.wordprocessingml.document" : nil)
        else { throw Abort(.unsupportedMediaType, reason: "Use PDF, JPEG, or PNG. Clinical attachments also accept DOCX.") }
        document.mediaType = type
        document.size = bytes.count
        document.data = bytes.base64EncodedString()
    }

    static func mediaType(_ bytes: Data) -> String? {
        if bytes.starts(with: "%PDF-".utf8) { return "application/pdf" }
        if bytes.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        if bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return "image/png" }
        return nil
    }
}

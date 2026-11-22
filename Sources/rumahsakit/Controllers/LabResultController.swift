import Fluent
import Vapor
import VaporToOpenAPI

struct LabResultController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let lab = routes.grouped("api", "lab-results")
        lab.get(use: index).openAPI(summary: "List lab results")
        lab.get(":id", use: show).openAPI(summary: "Get structured lab results")
        lab.get(":id", "pdf", use: pdf).openAPI(summary: "Download the published lab PDF")
        lab.post(use: create).openAPI(summary: "Publish a lab result", body: .type(LabResultInput.self))
    }

    @Sendable
    func index(req: Request) async throws -> [LabResultResponse] {
        let user = try req.auth.require(User.self)
        let patientId = try req.query[UUID.self, at: "patientId"] ?? user.requireID()
        try await PatientAccess.require(user, patientId: patientId, on: req.db)
        return try await LabResult.query(on: req.db).filter(\.$patientId == patientId)
            .sort(\.$collectedAt, .descending).all().map(LabResultResponse.init)
    }

    @Sendable
    func show(req: Request) async throws -> LabResultResponse {
        try await LabResultResponse(authorizedResult(req))
    }

    @Sendable
    func pdf(req: Request) async throws -> Response {
        let result = try await authorizedResult(req)
        guard let documentId = result.pdfDocumentId,
              let document = try await PatientDocument.find(documentId, on: req.db),
              document.patientId == result.patientId, document.mediaType == "application/pdf" else { throw Abort(.notFound) }
        return try document.fileResponse()
    }

    @Sendable
    func create(req: Request) async throws -> LabResultResponse {
        let user = try req.auth.require(User.self)
        guard user.role != .patient else { throw Abort(.forbidden) }
        let input = try req.content.decode(LabResultInput.self)
        try await PatientAccess.require(user, patientId: input.patientId, on: req.db)
        guard try await User.find(input.patientId, on: req.db)?.role == .patient else { throw Abort(.notFound) }
        guard !input.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, input.title.utf8.count <= 255,
              !input.laboratory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, input.laboratory.utf8.count <= 255,
              !input.panels.isEmpty, input.panels.allSatisfy({ !$0.name.isEmpty && !$0.measurements.isEmpty }) else { throw Abort(.badRequest) }
        let result = LabResult()
        result.patientId = input.patientId
        result.title = input.title
        result.laboratory = input.laboratory
        result.collectedAt = input.collectedAt
        result.alert = input.alert
        result.panels = input.panels
        result.doctorNote = input.doctorNote
        result.authorName = user.name
        if user.role == .doctor {
            result.authorSpecialty = try await Doctor.query(on: req.db).filter(\.$user.$id == user.requireID()).first()?.specialty
        }
        result.pdfDocumentId = input.pdfDocumentId
        return try await req.db.transaction { database in
            if let documentId = input.pdfDocumentId {
                try await PatientDocument.lock(documentId, on: database)
                guard let document = try await PatientDocument.summaryQuery(on: database).filter(\.$id == documentId).first(),
                      document.patientId == input.patientId, document.category == .clinicalAttachment,
                      document.mediaType == "application/pdf", document.deletedAt == nil else {
                    throw Abort(.badRequest, reason: "Use a PDF clinical attachment owned by the patient")
                }
            }
            try await result.create(on: database)
            return try LabResultResponse(result)
        }
    }

    private func authorizedResult(_ req: Request) async throws -> LabResult {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require("id", as: UUID.self)
        guard let result = try await LabResult.find(id, on: req.db) else { throw Abort(.notFound) }
        try await PatientAccess.require(user, patientId: result.patientId, on: req.db)
        return result
    }
}

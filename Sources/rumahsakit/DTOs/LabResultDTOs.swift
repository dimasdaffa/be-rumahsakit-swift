import Vapor

struct LabMeasurement: Content {
    let name: String
    let value: String
    let unit: String?
    let referenceRange: String?
    let status: String?
}

struct LabPanel: Content {
    let name: String
    let status: String?
    let summary: String?
    let measurements: [LabMeasurement]
}

struct LabResultInput: Content {
    let patientId: UUID
    let title: String
    let laboratory: String
    let collectedAt: Date
    let alert: String?
    let panels: [LabPanel]
    let doctorNote: String?
    let pdfDocumentId: UUID?
}

struct LabResultResponse: Content {
    let id: UUID
    let title: String
    let laboratory: String
    let collectedAt: Date
    let alert: String?
    let panels: [LabPanel]
    let doctorNote: String?
    let authorName: String?
    let authorSpecialty: String?
    let pdfPath: String?
    let createdAt: Date?

    init(_ result: LabResult) throws {
        id = try result.requireID()
        title = result.title
        laboratory = result.laboratory
        collectedAt = result.collectedAt
        alert = result.alert
        panels = result.panels
        doctorNote = result.doctorNote
        authorName = result.authorName
        authorSpecialty = result.authorSpecialty
        pdfPath = result.pdfDocumentId == nil ? nil : "/api/lab-results/\(id)/pdf"
        createdAt = result.createdAt
    }
}

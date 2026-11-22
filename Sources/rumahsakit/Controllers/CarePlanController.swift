import Fluent
import FluentSQL
import Vapor
import VaporToOpenAPI

struct CarePlanController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let carePlan = routes.grouped("api", "care-plan")
        carePlan.get(use: index).openAPI(summary: "Get the medication plan for a date")
        carePlan.put(":recordId", ":medicationId", "taken", use: markTaken)
            .openAPI(summary: "Mark a scheduled dose as taken", body: .type(MarkMedicationTakenRequest.self))
    }

    @Sendable
    func index(req: Request) async throws -> [CarePlanEntry] {
        let user = try req.auth.require(User.self)
        let patientId = try user.requireID()
        let day = req.query[String.self, at: "date"] ?? ClinicTime.dayString(Date())
        guard ClinicTime.day(day) != nil else { throw Abort(.badRequest) }
        let records = try await MedicalRecord.query(on: req.db).filter(\.$patient.$id == patientId)
            .filter(\.$medications != nil).all()
        let recordIds = try records.map { try $0.requireID() }
        guard !recordIds.isEmpty else { return [] }
        let intakes = try await MedicationIntake.query(on: req.db).filter(\.$recordId ~~ recordIds)
            .filter(\.$date == day).all()
        let intakesByRecord = Dictionary(grouping: intakes, by: \.recordId)
        return records.flatMap { record in
            let doses = intakesByRecord[record.id!] ?? []
            return (record.medications ?? []).filter { $0.isScheduled(on: day) }.flatMap { medication in
                medication.times.map { time in
                    CarePlanEntry(recordId: record.id!, medication: medication, date: day, time: time,
                                  takenAt: doses.first { $0.medicationId == medication.id && $0.time == time }?.takenAt)
                }
            }
        }.sorted { $0.time < $1.time }
    }

    @Sendable
    func markTaken(req: Request) async throws -> CarePlanEntry {
        let user = try req.auth.require(User.self)
        let recordId = try req.parameters.require("recordId", as: UUID.self)
        let medicationId = try req.parameters.require("medicationId", as: UUID.self)
        let input = try req.content.decode(MarkMedicationTakenRequest.self)
        guard ClinicTime.day(input.date) != nil, ClinicTime.minute(input.time) != nil,
              input.date <= ClinicTime.dayString(Date()) else { throw Abort(.badRequest) }
        return try await req.db.transaction { database in
            guard let sql = database as? any SQLDatabase else { throw Abort(.internalServerError) }
            _ = try await sql.raw("SELECT id FROM medical_records WHERE id = \(bind: recordId) FOR UPDATE").first()
            guard let record = try await MedicalRecord.find(recordId, on: database) else { throw Abort(.notFound) }
            guard user.id == record.$patient.id else { throw Abort(.forbidden) }
            guard let medication = record.medications?.first(where: { $0.id == medicationId }),
                  medication.isScheduled(on: input.date), medication.times.contains(input.time) else { throw Abort(.notFound) }
            let existing = try await MedicationIntake.query(on: database).filter(\.$recordId == recordId)
                .filter(\.$medicationId == medicationId).filter(\.$date == input.date).filter(\.$time == input.time).first()
            let intake = existing ?? MedicationIntake()
            if existing == nil {
                intake.recordId = recordId
                intake.medicationId = medicationId
                intake.date = input.date
                intake.time = input.time
                try await intake.create(on: database)
            }
            return CarePlanEntry(recordId: recordId, medication: medication, date: input.date, time: input.time, takenAt: intake.takenAt)
        }
    }
}

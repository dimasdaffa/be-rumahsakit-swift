import Fluent
import Vapor
import VaporToOpenAPI

struct MedicalRecordController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let records = routes.grouped("api", "medical-records")

        // LIST & SHOW
        records.get(use: index)
            .openAPI(summary: "List Medical Records")

        records.get(":id", use: show)
            .openAPI(summary: "Get Medical Record Details")

        records.get("patient", ":patientId", use: getByPatient)
            .openAPI(summary: "Get records for a specific patient")

        // CREATE (Doctor/Admin)
        records.post(use: create)
            .openAPI(
                summary: "Create Medical Record",
                body: .type(CreateMedicalRecordRequest.self)
            )

        // UPDATE & DELETE
        records.put(":id", use: update)
            .openAPI(
                summary: "Update Medical Record",
                body: .type(UpdateMedicalRecordRequest.self)
            )

        records.delete(":id", use: delete)
            .openAPI(summary: "Delete Medical Record")
    }

    // 1. CREATE RECORD (Doctors/Admins Only)
    @Sendable
    func create(req: Request) async throws -> MedicalRecord {
        // Ensure user is authorized (Doctor/Admin check should happen via middleware or here)
        let user = try req.auth.require(User.self)
        if user.role == .patient {
            throw Abort(.forbidden, reason: "Patients cannot create medical records")
        }

        let input = try req.content.decode(CreateMedicalRecordRequest.self)

        try validateDetails(type: input.recordType, severity: input.severity, medications: input.medications)
        return try await AppointmentController().withLockedAppointment(input.appointmentId, on: req.db) { appointment, database in
            if user.role == .doctor, appointment.$doctor.value?.$user.id != user.id { throw Abort(.forbidden) }
            guard ["pending", "approved", "completed"].contains(appointment.status) else { throw Abort(.conflict) }
            let record = MedicalRecord(
                appointmentId: input.appointmentId,
                patientId: appointment.$patient.id,  // Auto-link to Patient from Appointment
                diagnosis: input.diagnosis,
                symptoms: input.symptoms,
                treatment: input.treatment,
                prescription: input.prescription,
                notes: input.notes,

                // New Fields
                followUpRequired: input.followUpRequired,
                followUpDate: input.followUpDate,

                // Unpack Vitals
                vitalBloodPressure: input.vitalSigns?.bloodPressure,
                vitalHeartRate: input.vitalSigns?.heartRate,
                vitalTemperature: input.vitalSigns?.temperature,
                vitalWeight: input.vitalSigns?.weight
            )
            record.recordType = input.recordType ?? "diagnosis"
            record.severity = input.severity
            record.symptomTags = input.symptomTags
            record.medications = input.medications
            appointment.status = "completed"
            try await appointment.save(on: database)
            try await record.create(on: database)
            return record
        }
    }

    // 2. LIST RECORDS
    @Sendable
    func index(req: Request) async throws -> [MedicalRecord] {
        let user = try req.auth.require(User.self)

        let query = MedicalRecord.query(on: req.db).with(\.$appointment) { $0.with(\.$doctor) }
        if user.role == .patient {
            query.filter(\.$patient.$id == user.id!)
        } else if user.role == .doctor {
            let doctorId = try await PatientAccess.doctorId(for: user, on: req.db)
            let appointments = try await Appointment.query(on: req.db).filter(\.$doctor.$id == doctorId)
                .all(\.$id).compactMap { $0 }
            guard !appointments.isEmpty else { return [] }
            query.filter(\.$appointment.$id ~~ appointments)
        }
        return try await filtered(query, req: req)
    }

    @Sendable
    func show(req: Request) async throws -> MedicalRecord {
        let user = try req.auth.require(User.self)
        let id = try req.parameters.require("id", as: UUID.self)
        guard let record = try await MedicalRecord.query(on: req.db).filter(\.$id == id)
            .with(\.$appointment, { $0.with(\.$doctor) }).first() else { throw Abort(.notFound) }
        try await PatientAccess.requireRecord(user, record: record, on: req.db)
        return record
    }

    // 4. UPDATE RECORD
    @Sendable
    func update(req: Request) async throws -> MedicalRecord {
        let user = try req.auth.require(User.self)

        guard let record = try await MedicalRecord.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }

        // Authorization: Admin OR the Doctor who owns the appointment
        if user.role == .doctor {
            // Eager load the appointment -> doctor relationship to verify ownership
            // Note: This requires the record to be loaded with appointment/doctor info
            // For simplicity, we query the appointment separately if needed,
            // or assume if user is doctor, they must verify against the record's appointment.

            // Let's verify via Appointment linkage
            guard let appointment = try await Appointment.find(record.$appointment.id, on: req.db)
            else {
                throw Abort(.notFound, reason: "Associated appointment not found")
            }

            // Get Doctor Profile of current user
            guard
                let doctorProfile = try await Doctor.query(on: req.db)
                    .filter(\.$user.$id == user.id!)
                    .first()
            else {
                throw Abort(.forbidden, reason: "Doctor profile not found")
            }

            guard appointment.$doctor.id == doctorProfile.id else {
                throw Abort(
                    .forbidden, reason: "You can only edit records for your own appointments")
            }
        } else if user.role != .admin {
            throw Abort(.forbidden)
        }

        // Decode Update Data
        let input = try req.content.decode(UpdateMedicalRecordRequest.self)
        try validateDetails(type: input.recordType, severity: input.severity, medications: input.medications)
        if let type = input.recordType { record.recordType = type }
        if let severity = input.severity { record.severity = severity }
        if let tags = input.symptomTags { record.symptomTags = tags }
        if let medications = input.medications { record.medications = medications }

        if let d = input.diagnosis { record.diagnosis = d }
        if let s = input.symptoms { record.symptoms = s }
        if let t = input.treatment { record.treatment = t }
        if let p = input.prescription { record.prescription = p }
        if let n = input.notes { record.notes = n }
        if let fr = input.followUpRequired { record.followUpRequired = fr }
        if let fd = input.followUpDate { record.followUpDate = fd }

        // Update Vitals (Flattened)
        if let v = input.vitalSigns {
            if let bp = v.bloodPressure { record.vitalBloodPressure = bp }
            if let hr = v.heartRate { record.vitalHeartRate = hr }
            if let temp = v.temperature { record.vitalTemperature = temp }
            if let w = v.weight { record.vitalWeight = w }
        }

        try await record.save(on: req.db)
        return record
    }

    // 5. DELETE RECORD
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)

        guard let record = try await MedicalRecord.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }

        // Authorization: Admin Only (Medical records are sensitive)
        // Or strictly allow the creating doctor.
        // For safety, let's keep DELETE to Admins only for now.
        guard user.role == .admin else {
            throw Abort(.forbidden, reason: "Only Admins can delete medical records")
        }

        try await record.delete(on: req.db)
        return .noContent
    }
    
    // 6. GET RECORDS BY PATIENT
    @Sendable
    func getByPatient(req: Request) async throws -> [MedicalRecord] {
        let user = try req.auth.require(User.self)
        guard let patientId = req.parameters.get("patientId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        try await PatientAccess.require(user, patientId: patientId, on: req.db)
        let query = MedicalRecord.query(on: req.db).filter(\.$patient.$id == patientId)
            .with(\.$appointment) { $0.with(\.$doctor) }
        return try await filtered(query, req: req)
    }

    private func filtered(_ query: QueryBuilder<MedicalRecord>, req: Request) async throws -> [MedicalRecord] {
        if let type = req.query[String.self, at: "type"] {
            try validateDetails(type: type, severity: nil, medications: nil)
            if type == "diagnosis" {
                query.group(.or) { $0.filter(\.$recordType == type).filter(\.$recordType == nil) }
            } else {
                query.filter(\.$recordType == type)
            }
        }
        let search = req.query[String.self, at: "q"] ?? ""
        if !search.isEmpty {
            query.group(.or) { $0.filter(\.$diagnosis ~~ search).filter(\.$symptoms ~~ search) }
        }
        return try await query.sort(\.$createdAt, .descending).all()
    }

    private func validateDetails(type: String?, severity: String?, medications: [PrescribedMedication]?) throws {
        if let type, !["diagnosis", "vaccination"].contains(type) { throw Abort(.badRequest, reason: "Unknown record type") }
        if let severity, !["mild", "moderate", "severe"].contains(severity) { throw Abort(.badRequest, reason: "Unknown severity") }
        if let medications, !medications.allSatisfy(\.isValid) || Set(medications.map(\.id)).count != medications.count {
            throw Abort(.badRequest, reason: "Invalid or repeated medication schedule")
        }
    }
}

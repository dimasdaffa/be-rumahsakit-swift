import Vapor
import Fluent
import VaporToOpenAPI

struct MedicalRecordController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let records = routes.grouped("api", "medical-records")
        
        records.get(use: index)
        
        records.post(use: create)
            .openAPI(
                summary: "Create Medical Record",
                body: .type(CreateMedicalRecordRequest.self)
            )
        
        records.get(":id", use: show)
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
        
        // Find appointment
        guard let appointment = try await Appointment.find(input.appointmentId, on: req.db) else {
            throw Abort(.notFound, reason: "Appointment not found")
        }
        
        // Create Record
        let record = MedicalRecord(
            appointmentId: input.appointmentId,
            patientId: appointment.$patient.id, // Auto-link to Patient from Appointment
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
        
        // Automatically mark appointment as "completed"
        appointment.status = "completed"
        try await appointment.save(on: req.db)
        
        try await record.save(on: req.db)
        return record
    }

    // 2. LIST RECORDS
    @Sendable
    func index(req: Request) async throws -> [MedicalRecord] {
        let user = try req.auth.require(User.self)
        
        if user.role == .patient {
            // Patient: See MY records
            return try await MedicalRecord.query(on: req.db)
                .filter(\.$patient.$id == user.id!)
                .with(\.$appointment)
                .all()
        } else {
            // Doctor/Admin: See ALL records (or add logic to filter by doctor if needed)
            return try await MedicalRecord.query(on: req.db)
                .with(\.$patient)
                .with(\.$appointment)
                .all()
        }
    }
    
    // 3. SHOW DETAIL
    @Sendable
    func show(req: Request) async throws -> MedicalRecord {
        guard let record = try await MedicalRecord.find(req.parameters.get("id"), on: req.db) else {
             throw Abort(.notFound)
        }
        // Ideally add security check here (is this my record?)
        return record
    }
}
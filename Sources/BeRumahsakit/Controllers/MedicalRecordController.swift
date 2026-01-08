import Vapor
import Fluent
import VaporToOpenAPI

struct MedicalRecordController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let records = routes.grouped("api", "medical-records")
        
        // GET /api/medical-records (View My Records)
        records.get(use: index)
        
        // POST /api/medical-records (Doctor Creates Record)
        records.post(use: create)
            .openAPI(
                summary: "Create Medical Record",
                body: .type(CreateMedicalRecordRequest.self)
            )
        
        // GET /api/medical-records/:id (View Details)
        records.get(":id", use: show)
    }

    // 1. CREATE RECORD (Doctors/Admins Only)
    @Sendable
    func create(req: Request) async throws -> MedicalRecord {
        let input = try req.content.decode(CreateMedicalRecordRequest.self)
        
        // Find the appointment to get the Patient ID
        guard let appointment = try await Appointment.find(input.appointmentId, on: req.db) else {
            throw Abort(.notFound, reason: "Appointment not found")
        }
        
        // Create Record
        let record = MedicalRecord(
            appointmentId: input.appointmentId,
            patientId: appointment.$patient.id, // Auto-link to Patient
            diagnosis: input.diagnosis,
            symptoms: input.symptoms,
            treatment: input.treatment,
            prescription: input.prescription,
            notes: input.notes
        )
        
        // Mark appointment as "completed" automatically!
        appointment.status = "completed"
        try await appointment.save(on: req.db)
        
        try await record.save(on: req.db)
        return record
    }

    // 2. LIST RECORDS (Patients see theirs, Doctors/Admin see all)
    @Sendable
    func index(req: Request) async throws -> [MedicalRecord] {
        let user = try req.auth.require(User.self)
        
        if user.role == .patient {
            // Patient: Only see MY records
            return try await MedicalRecord.query(on: req.db)
                .filter(\.$patient.$id == user.id!)
                .with(\.$appointment) // Include appointment details
                .all()
        } else {
            // Doctor/Admin: See ALL records
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
        return record
    }
}
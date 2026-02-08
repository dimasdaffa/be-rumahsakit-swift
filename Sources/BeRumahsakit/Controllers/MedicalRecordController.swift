import Vapor
import Fluent
import VaporToOpenAPI

struct MedicalRecordController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let records = routes.grouped("api", "medical-records")
        
        // LIST & SHOW
        records.get(use: index)
            .openAPI(summary: "List Medical Records")
        
        records.get(":id", use: show)
            .openAPI(summary: "Get Medical Record Details")
        
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
            guard let appointment = try await Appointment.find(record.$appointment.id, on: req.db) else {
                throw Abort(.notFound, reason: "Associated appointment not found")
            }
            
            // Get Doctor Profile of current user
            guard let doctorProfile = try await Doctor.query(on: req.db)
                .filter(\.$user.$id == user.id!)
                .first() else {
                throw Abort(.forbidden, reason: "Doctor profile not found")
            }
            
            guard appointment.$doctor.id == doctorProfile.id else {
                throw Abort(.forbidden, reason: "You can only edit records for your own appointments")
            }
        } else if user.role != .admin {
            throw Abort(.forbidden)
        }
        
        // Decode Update Data
        let input = try req.content.decode(UpdateMedicalRecordRequest.self)
        
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
}
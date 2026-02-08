import Vapor
import Fluent
import VaporToOpenAPI

struct ClinicalNoteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let notes = routes.grouped("api", "clinical-notes")
        
        // LIST
        notes.get(use: index)
            .openAPI(summary: "List Clinical Notes")
        
        // DOCTOR ONLY: Create
        notes.post(use: create)
            .openAPI(
                summary: "Create Clinical Note",
                body: .type(CreateClinicalNoteRequest.self)
            )
            
        // DETAILS
        notes.group(":id") { note in
            note.get(use: show)
                .openAPI(summary: "Get Clinical Note Details")
                
            note.put(use: update)
                .openAPI(
                    summary: "Update Clinical Note",
                    body: .type(UpdateClinicalNoteRequest.self)
                )
                
            note.delete(use: delete)
                .openAPI(summary: "Delete Clinical Note")
        }
    }

    // GET /api/clinical-notes
    @Sendable
    func index(req: Request) async throws -> [ClinicalNote] {
        let user = try req.auth.require(User.self)
        
        // 1. Admin sees all
        if user.role == .admin {
            return try await ClinicalNote.query(on: req.db)
                .with(\.$doctor)
                .with(\.$patient)
                .all()
        }
        // 2. Doctor sees only notes they created
        else if user.role == .doctor {
            guard let doctor = try await Doctor.query(on: req.db).filter(\.$user.$id == user.id!).first() else {
                throw Abort(.forbidden, reason: "Doctor profile not found")
            }
            return try await ClinicalNote.query(on: req.db)
                .filter(\.$doctor.$id == doctor.id!)
                .with(\.$patient)
                .all()
        }
        // 3. Patients cannot see these notes (internal clinical notes) - Check Spec?
        // Spec says: "Doctors: See notes they created, Admins: See all". 
        // It does NOT explicitly say Patients can see them. We will restrict for now.
        else {
            throw Abort(.forbidden, reason: "Access denied")
        }
    }

    // POST /api/clinical-notes
    @Sendable
    func create(req: Request) async throws -> ClinicalNote {
        let user = try req.auth.require(User.self)
        guard user.role == .doctor else {
            throw Abort(.forbidden, reason: "Only doctors can create clinical notes")
        }
        
        // Find Doctor Profile
        guard let doctor = try await Doctor.query(on: req.db).filter(\.$user.$id == user.id!).first() else {
            throw Abort(.notFound, reason: "Doctor profile not found")
        }
        
        let input = try req.content.decode(CreateClinicalNoteRequest.self)
        
        let note = ClinicalNote(
            doctorId: doctor.id!,
            patientId: input.patientId,
            appointmentId: input.appointmentId,
            diagnosis: input.diagnosis,
            treatment: input.treatment,
            notes: input.notes,
            followUpDate: input.followUp,
            status: input.status
        )
        
        try await note.save(on: req.db)
        return note
    }

    // GET /api/clinical-notes/:id
    @Sendable
    func show(req: Request) async throws -> ClinicalNote {
        guard let note = try await ClinicalNote.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        return note
    }

    // PUT /api/clinical-notes/:id
    @Sendable
    func update(req: Request) async throws -> ClinicalNote {
        let user = try req.auth.require(User.self)
        guard let note = try await ClinicalNote.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Only Admin or Creator (Doctor) can update
        if user.role == .doctor {
            // Verify ownership
            guard let doctor = try await Doctor.query(on: req.db).filter(\.$user.$id == user.id!).first(),
                  doctor.id == note.$doctor.id else {
                throw Abort(.forbidden, reason: "You can only edit your own notes")
            }
        } else if user.role != .admin {
            throw Abort(.forbidden)
        }
        
        let input = try req.content.decode(UpdateClinicalNoteRequest.self)
        if let d = input.diagnosis { note.diagnosis = d }
        if let t = input.treatment { note.treatment = t }
        if let n = input.notes { note.notes = n }
        if let f = input.followUp { note.followUpDate = f }
        if let s = input.status { note.status = s }
        
        try await note.save(on: req.db)
        return note
    }

    // DELETE /api/clinical-notes/:id
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard user.role == .admin else {
            throw Abort(.forbidden, reason: "Only admins can delete clinical notes")
        }
        
        guard let note = try await ClinicalNote.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await note.delete(on: req.db)
        return .noContent
    }
}
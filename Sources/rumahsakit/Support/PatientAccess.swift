import Fluent
import Vapor

enum PatientAccess {
    static func doctorId(for user: User, on db: any Database) async throws -> UUID {
        guard let doctor = try await Doctor.query(on: db).filter(\.$user.$id == user.requireID()).first() else {
            throw Abort(.forbidden)
        }
        return try doctor.requireID()
    }

    static func require(_ user: User, patientId: UUID, on db: any Database) async throws {
        if user.role == .admin || user.id == patientId { return }
        if user.role == .doctor {
            let doctorId = try await doctorId(for: user, on: db)
            if try await Appointment.query(on: db)
                .filter(\.$patient.$id == patientId).filter(\.$doctor.$id == doctorId)
                .filter(\.$status ~~ ["approved", "completed"]).first() != nil { return }
        }
        throw Abort(.forbidden)
    }

    static func requireRecord(_ user: User, record: MedicalRecord, on db: any Database) async throws {
        if user.role == .admin || user.id == record.$patient.id { return }
        if user.role == .doctor,
           let appointment = try await Appointment.find(record.$appointment.id, on: db),
           try await doctorId(for: user, on: db) == appointment.$doctor.id { return }
        throw Abort(.forbidden)
    }
}

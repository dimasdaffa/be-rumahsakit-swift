import Fluent

struct AddUserPatientFields: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .field("avatar_url", .string).field("appointment_notifications", .bool).update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(User.schema).deleteField("avatar_url").deleteField("appointment_notifications").update()
    }
}

struct AddDoctorPatientFields: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Doctor.schema)
            .field("avatar_url", .string).field("review_count", .int).field("practice", .dictionary).update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Doctor.schema)
            .deleteField("avatar_url").deleteField("review_count").deleteField("practice").update()
    }
}

struct AddAppointmentPatientFields: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(Appointment.schema)
            .field("cancellation_reason", .string).field("cancellation_note", .string)
            .field("pre_cancellation_status", .string).field("booking_key", .string)
            .unique(on: "patient_id", "doctor_id", "booking_key").update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(Appointment.schema).deleteUnique(on: "patient_id", "doctor_id", "booking_key").update()
        try await database.schema(Appointment.schema)
            .deleteField("cancellation_reason").deleteField("cancellation_note")
            .deleteField("pre_cancellation_status").deleteField("booking_key").update()
    }
}

struct CreateDoctorFavorites: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(DoctorFavorite.schema).id()
            .field("user_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("doctor_id", .uuid, .required, .references(Doctor.schema, .id, onDelete: .cascade))
            .unique(on: "user_id", "doctor_id").create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(DoctorFavorite.schema).delete()
    }
}

struct CreatePatientNotifications: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(PatientNotification.schema).id()
            .field("patient_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("appointment_id", .uuid, .required, .references(Appointment.schema, .id, onDelete: .cascade))
            .field("type", .string, .required).field("read_at", .datetime).field("created_at", .datetime).create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(PatientNotification.schema).delete()
    }
}

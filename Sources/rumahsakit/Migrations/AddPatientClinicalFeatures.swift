import Fluent
import FluentSQL

struct AddMedicalRecordPatientFields: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(MedicalRecord.schema)
            .field("record_type", .string).field("severity", .string)
            .field("symptom_tags", .array).field("medications", .array).update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(MedicalRecord.schema)
            .deleteField("record_type").deleteField("severity")
            .deleteField("symptom_tags").deleteField("medications").update()
    }
}

struct AddHealthMeasurementTime: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(HealthUpdate.schema).field("measured_at", .datetime).update()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(HealthUpdate.schema).deleteField("measured_at").update()
    }
}

struct CreatePatientDocuments: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(PatientDocument.schema).id()
            .field("patient_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("medical_record_id", .uuid, .references(MedicalRecord.schema, .id, onDelete: .setNull))
            .field("name", .string, .required).field("card_number", .string)
            .field("category", .string, .required).field("media_type", .string, .required).field("size", .int, .required)
            .field("data", .custom(SQLRaw("MEDIUMTEXT"))).field("deleted_at", .datetime)
            .field("created_at", .datetime).field("updated_at", .datetime).create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(PatientDocument.schema).delete()
    }
}

struct CreateLabResults: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(LabResult.schema).id()
            .field("patient_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("title", .string, .required).field("laboratory", .string, .required)
            .field("collected_at", .datetime, .required).field("alert", .custom(SQLRaw("TEXT")))
            .field("panels", .array, .required).field("doctor_note", .custom(SQLRaw("TEXT")))
            .field("author_name", .string).field("author_specialty", .string)
            .field("pdf_document_id", .uuid, .references(PatientDocument.schema, .id, onDelete: .setNull))
            .field("created_at", .datetime).create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(LabResult.schema).delete()
    }
}

struct CreateMedicationIntakes: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema(MedicationIntake.schema).id()
            .field("record_id", .uuid, .required, .references(MedicalRecord.schema, .id, onDelete: .cascade))
            .field("medication_id", .uuid, .required).field("date", .string, .required).field("time", .string, .required)
            .field("taken_at", .datetime).unique(on: "record_id", "medication_id", "date", "time").create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema(MedicationIntake.schema).delete()
    }
}

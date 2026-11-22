import Vapor

struct PrescribedMedication: Content {
    let id: UUID
    let name: String
    let dose: String
    let category: String?
    let instructions: String?
    let startsOn: String
    let endsOn: String
    let times: [String]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !dose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        ClinicTime.day(startsOn) != nil && ClinicTime.day(endsOn) != nil && startsOn <= endsOn &&
        times.count <= 24 && Set(times).count == times.count && times.allSatisfy { ClinicTime.minute($0) != nil }
    }

    func isScheduled(on day: String) -> Bool { startsOn <= day && day <= endsOn }
}

struct CarePlanEntry: Content {
    let recordId: UUID
    let medication: PrescribedMedication
    let date: String
    let time: String
    let takenAt: Date?
}

struct MarkMedicationTakenRequest: Content {
    let date: String
    let time: String
}

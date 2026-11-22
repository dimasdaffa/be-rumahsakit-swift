@testable import rumahsakit
import Foundation
import Testing
import VaporTesting

@Suite("Patient API")
struct BeRumahsakitTests {
    @Test("Health is public and patient routes require authentication")
    func access() async throws {
        try await withApp(configure: configure) { app in
            try await app.testing().test(.GET, "health") { response async in
                #expect(response.status == .ok)
                #expect(response.body.string.contains("healthy"))
            }
            for path in ["api/doctors", "api/documents", "api/lab-results", "api/care-plan", "api/notifications", "api/messages/conversations"] {
                try await app.testing().test(.GET, path) { response async in
                    #expect(response.status == .unauthorized)
                }
            }
        }
    }

    @Test("A cancellation request keeps the slot occupied until approval")
    func availability() throws {
        let doctorId = UUID()
        let date = "2026-12-07"
        let day = try #require(ClinicTime.day(date))
        let schedule = Schedule(doctorId: doctorId, dayOfWeek: "Monday", startTime: "09:00", endTime: "10:00")
        let appointment = Appointment(patientId: UUID(), doctorId: doctorId, date: date, time: "09:00",
                                      reason: "Checkup", status: "cancellation_requested")
        let slots = BookingSlots.slots(on: day, schedules: [schedule], appointments: [appointment], now: day)
        #expect(slots.map(\.time) == ["09:00", "09:30"])
        #expect(slots.map(\.available) == [false, true])
        appointment.status = "cancelled"
        let releasedSlots = BookingSlots.slots(on: day, schedules: [schedule], appointments: [appointment], now: day)
        #expect(releasedSlots.map(\.available) == [true, true])
        #expect(ClinicTime.day("2026-02-30") == nil)
        #expect(ClinicTime.minute("09:6") == nil)
    }

    @Test("Document uploads check file signatures and user JSON omits password hashes")
    func privateData() throws {
        #expect(DocumentController.mediaType(Data("%PDF-1.7".utf8)) == "application/pdf")
        #expect(DocumentController.mediaType(Data("document.pdf".utf8)) == nil)
        let user = User(id: UUID(), name: "Dummy", email: "dummy@example.test", passwordHash: "opaque", role: .patient)
        let json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(user)) as? [String: Any])
        #expect(json["name"] as? String == "Dummy")
        #expect(json["passwordHash"] == nil)
    }
}

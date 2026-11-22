import Fluent
import FluentSQL
import Vapor

struct AppointmentSlot: Content, Equatable {
    let date: String
    let time: String
    let endTime: String
    let available: Bool
}

enum BookingSlots {
    static let duration = 30
    static let occupyingStatuses = ["pending", "approved", "cancellation_requested", "completed"]
    static let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]

    // Lock the same doctor row for every booking mutation, including across Vapor replicas.
    static func lockDoctor(_ id: UUID, on database: any Database) async throws {
        guard let sql = database as? any SQLDatabase else { throw Abort(.internalServerError) }
        guard try await sql.raw("SELECT id FROM doctors WHERE id = \(bind: id) FOR UPDATE").first() != nil else {
            throw Abort(.notFound, reason: "Doctor not found")
        }
    }

    static func slots(on day: Date, schedules: [Schedule], appointments: [Appointment], now: Date) -> [AppointmentSlot] {
        let calendar = ClinicTime.calendar
        let date = ClinicTime.dayString(day)
        let weekday = weekdays[calendar.component(.weekday, from: day) - 1]
        let starts = schedules.flatMap { schedule -> [Int] in
            guard schedule.isAvailable, schedule.dayOfWeek.lowercased() == weekday,
                  let start = ClinicTime.minute(schedule.startTime),
                  let end = ClinicTime.minute(schedule.endTime), end - start >= duration else { return [] }
            return Array(stride(from: start, through: end - duration, by: duration))
        }
        let occupied = appointments.compactMap { appointment -> Int? in
            guard appointment.date == date, occupyingStatuses.contains(appointment.status) else { return nil }
            return ClinicTime.minute(appointment.time)
        }
        return Set(starts).sorted().map { start in
            let conflict = occupied.contains { abs($0 - start) < duration }
            return AppointmentSlot(
                date: date, time: ClinicTime.clock(start), endTime: ClinicTime.clock(start + duration),
                available: !conflict && day.addingTimeInterval(Double(start * 60)) > now
            )
        }
    }

    static func requireAvailable(doctorId: UUID, date: String, time: String, excluding: UUID? = nil, on db: any Database) async throws {
        guard let day = ClinicTime.day(date), let minute = ClinicTime.minute(time),
              day.addingTimeInterval(Double(minute * 60)) > Date() else {
            throw Abort(.badRequest, reason: "Provide a future date and time in Asia/Jakarta")
        }
        let schedules = try await Schedule.query(on: db).filter(\.$doctor.$id == doctorId).all()
        let appointments = try await Appointment.query(on: db)
            .filter(\.$doctor.$id == doctorId).filter(\.$date == date)
            .filter(\.$status ~~ occupyingStatuses).all()
        let slot = slots(on: day, schedules: schedules, appointments: appointments.filter { $0.id != excluding }, now: Date())
            .first { $0.time == time }
        guard let slot else { throw Abort(.unprocessableEntity, reason: "Time is outside available practice slots") }
        guard slot.available else { throw Abort(.conflict, reason: "Slot already taken") }
    }
}

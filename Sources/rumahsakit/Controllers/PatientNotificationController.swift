import Fluent
import Vapor
import VaporToOpenAPI

struct AppointmentNotificationSettings: Content {
    let appointmentUpdates: Bool
}

struct HelpTopic: Content {
    let title: String
    let answer: String
}

struct PatientNotificationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let notifications = routes.grouped("api", "notifications")
        notifications.get(use: index).openAPI(summary: "List your appointment notifications")
        notifications.put(":id", "read", use: markRead).openAPI(summary: "Mark a notification as read")
        let settings = routes.grouped("api", "users", "me", "notification-settings")
        settings.get(use: getSettings).openAPI(summary: "Get appointment notification preferences")
        settings.put(use: setSettings).openAPI(summary: "Update notification preferences", body: .type(AppointmentNotificationSettings.self))
        routes.get("api", "help-center", use: help).openAPI(summary: "Read help topics for the patient app")
    }

    @Sendable
    func index(req: Request) async throws -> [PatientNotification] {
        let patientId = try req.auth.require(User.self).requireID()
        let query = PatientNotification.query(on: req.db).filter(\.$patientId == patientId)
        if req.query[Bool.self, at: "unread"] == true { query.filter(\.$readAt == nil) }
        return try await query.sort(\.$createdAt, .descending).all()
    }

    @Sendable
    func markRead(req: Request) async throws -> HTTPStatus {
        let patientId = try req.auth.require(User.self).requireID()
        let id = try req.parameters.require("id", as: UUID.self)
        guard try await PatientNotification.query(on: req.db)
            .filter(\.$id == id).filter(\.$patientId == patientId).first() != nil else { throw Abort(.notFound) }
        try await PatientNotification.query(on: req.db).filter(\.$id == id).filter(\.$patientId == patientId)
            .filter(\.$readAt == nil).set(\.$readAt, to: Date()).update()
        return .noContent
    }

    @Sendable
    func getSettings(req: Request) throws -> AppointmentNotificationSettings {
        let user = try req.auth.require(User.self)
        return AppointmentNotificationSettings(appointmentUpdates: user.appointmentNotifications ?? true)
    }

    @Sendable
    func setSettings(req: Request) async throws -> AppointmentNotificationSettings {
        let user = try req.auth.require(User.self)
        let settings = try req.content.decode(AppointmentNotificationSettings.self)
        user.appointmentNotifications = settings.appointmentUpdates
        try await user.update(on: req.db)
        return settings
    }

    @Sendable
    func help(req: Request) -> [HelpTopic] {
        [
            HelpTopic(title: "Booking dokter", answer: "Pilih dokter, slot praktik, lalu isi alasan kunjungan. Status permintaan tersedia di My Appointments."),
            HelpTopic(title: "Mengubah atau membatalkan jadwal", answer: "Buka appointment aktif untuk memilih slot baru atau mengirim permintaan pembatalan."),
            HelpTopic(title: "Mengunggah dokumen", answer: "Buka Documents & BPJS. Pilih PDF, JPEG, atau PNG dengan ukuran maksimal 5 MiB.")
        ]
    }
}

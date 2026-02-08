import Vapor

struct CreateScheduleRequest: Content {
    var dayOfWeek: String
    var startTime: String
    var endTime: String
    var isAvailable: Bool
}

struct UpdateScheduleRequest: Content {
    var dayOfWeek: String?
    var startTime: String?
    var endTime: String?
    var isAvailable: Bool?
}
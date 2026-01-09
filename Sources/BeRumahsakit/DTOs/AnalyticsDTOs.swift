import Vapor

struct DashboardStats: Content {
    var totalPatients: Int
    var totalDoctors: Int
    var pendingAppointments: Int
    var completedToday: Int
}
import Vapor

// 1. Existing Dashboard DTO 
struct DashboardStats: Content {
    var totalPatients: Int
    var totalDoctors: Int
    var totalAppointments: Int
    var revenue: Double // Placeholder for future logic
}

// 2. NEW: Appointment Analytics 📊
struct AppointmentStatsResponse: Content {
    var total: Int
    var pending: Int
    var approved: Int
    var rejected: Int
    var completed: Int
    var cancelled: Int
}

// 3. NEW: Doctor Performance 🏆
struct DoctorPerformanceResponse: Content {
    var doctorId: UUID
    var name: String
    var specialty: String
    var totalPatients: Int
    var rating: Double
    var appointmentCount: Int // How many appointments they have
}

struct HealthStatsResponse: Content {
    var diagnosis: String
    var count: Int
}
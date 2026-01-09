import Vapor
import Fluent
import VaporToOpenAPI

struct AnalyticsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let analytics = routes.grouped("api", "analytics")
        
        // GET /api/analytics/dashboard
        analytics.get("dashboard", use: getDashboardStats)
            .openAPI(summary: "Get Admin Dashboard Stats")
    }

    @Sendable
    func getDashboardStats(req: Request) async throws -> DashboardStats {
        // 1. Count Patients 👥 (Users who are patients)
        let totalPatients = try await User.query(on: req.db)
            .filter(\.$role == .patient)
            .count()
        
        // 2. Count Doctors 👨‍⚕️
        let totalDoctors = try await Doctor.query(on: req.db)
            .count()
        
        // 3. Count Pending Appointments ⏳
        let pending = try await Appointment.query(on: req.db)
            .filter(\.$status == "pending")
            .count()
        
        // 4. Count Completed Today ✅
        // Note: We need to match your String date format "YYYY-MM-DD"
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        
        let completedToday = try await Appointment.query(on: req.db)
            .filter(\.$status == "completed")
            .filter(\.$date == todayString)
            .count()
        
        // Return the Package 📦
        return DashboardStats(
            totalPatients: totalPatients,
            totalDoctors: totalDoctors,
            pendingAppointments: pending,
            completedToday: completedToday
        )
    }
}
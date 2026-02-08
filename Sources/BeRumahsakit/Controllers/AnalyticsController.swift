import Fluent
import Vapor
import VaporToOpenAPI

struct AnalyticsController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let analytics = routes.grouped("api", "analytics")

        // ADMIN ONLY GROUP
        // (Security check is handled in routes.swift via the adminOnly group)

        // 1. General Dashboard
        analytics.get("dashboard", use: getDashboard)
            .openAPI(summary: "Get general system stats")

        // 2. Appointment Stats
        analytics.get("appointments", use: getAppointmentStats)
            .openAPI(summary: "Get appointment breakdown by status")

        // 3. Doctor Performance
        analytics.get("doctors", use: getDoctorStats)
            .openAPI(summary: "Get doctor performance metrics")
    }

    @Sendable
    func getDashboard(req: Request) async throws -> DashboardStats {
        // Simple counts
        let patients = try await User.query(on: req.db).filter(\.$role == .patient).count()
        let doctors = try await Doctor.query(on: req.db).count()
        let appointments = try await Appointment.query(on: req.db).count()

        return DashboardStats(
            totalPatients: patients,
            totalDoctors: doctors,
            totalAppointments: appointments,
            revenue: 0.0  // Placeholder
        )
    }

    @Sendable
    func getAppointmentStats(req: Request) async throws -> AppointmentStatsResponse {
        // We can do this with one query using groups, or multiple counts.
        // For simplicity and readability in Fluent, multiple counts is fine for small-medium apps.

        let total = try await Appointment.query(on: req.db).count()
        let pending = try await Appointment.query(on: req.db).filter(\.$status == "pending").count()
        let approved = try await Appointment.query(on: req.db).filter(\.$status == "approved")
            .count()
        let rejected = try await Appointment.query(on: req.db).filter(\.$status == "rejected")
            .count()
        let completed = try await Appointment.query(on: req.db).filter(\.$status == "completed")
            .count()

        // "cancelled" might be handled by deleting, but if you have a status for it:
        // Let's assume you might add "cancelled" status later or count deleted ones if soft-delete is on.
        // For now, we return 0 or query specific status if you use it.
        let cancelled = try await Appointment.query(on: req.db).filter(\.$status == "cancelled")
            .count()

        return AppointmentStatsResponse(
            total: total,
            pending: pending,
            approved: approved,
            rejected: rejected,
            completed: completed,
            cancelled: cancelled
        )
    }

    @Sendable
    func getDoctorStats(req: Request) async throws -> [DoctorPerformanceResponse] {
        // Get all doctors
        let doctors = try await Doctor.query(on: req.db).all()

        var stats: [DoctorPerformanceResponse] = []

        for doc in doctors {
            // Count appointments for this doctor
            let apptCount = try await Appointment.query(on: req.db)
                .filter(\.$doctor.$id == doc.id!)
                .count()

            stats.append(
                DoctorPerformanceResponse(
                    doctorId: doc.id!,
                    name: doc.name,
                    specialty: doc.specialty,
                    totalPatients: doc.totalPatients,  // Use the field from Doctor model
                    rating: doc.rating,  // Use the field from Doctor model
                    appointmentCount: apptCount
                ))
        }

        // Sort by busiest (most appointments)
        return stats.sorted { $0.appointmentCount > $1.appointmentCount }
    }
}

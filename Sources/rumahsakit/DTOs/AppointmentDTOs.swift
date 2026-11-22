import Vapor

struct AppointmentResponse: Content {
    let id: UUID
    let patient: AppointmentPatient
    let doctor: DoctorPublicResponse?
    let patientId: UUID
    let doctorId: UUID
    let date: String
    let time: String
    let endTime: String?
    let reason: String
    let complaints: String?
    let status: String
    let referenceNumber: String
    let cancellationReason: String?
    let cancellationNote: String?
    let createdAt: Date?

    init(_ appointment: Appointment) throws {
        id = try appointment.requireID()
        patient = AppointmentPatient(appointment.$patient.id, user: appointment.$patient.value)
        doctor = appointment.$doctor.value.map { DoctorPublicResponse($0) }
        patientId = appointment.$patient.id
        doctorId = appointment.$doctor.id
        date = appointment.date
        time = appointment.time
        endTime = ClinicTime.minute(time).flatMap { start in
            start + BookingSlots.duration <= 24 * 60 ? ClinicTime.clock(start + BookingSlots.duration) : nil
        }
        reason = appointment.reason
        complaints = appointment.complaints
        status = appointment.status
        referenceNumber = "REF-\(id.uuidString)"
        cancellationReason = appointment.cancellationReason
        cancellationNote = appointment.cancellationNote
        createdAt = appointment.createdAt
    }
}

struct AppointmentPatient: Content {
    let id: UUID
    let name: String?
    let email: String?
    let role: UserRole?
    let phone: String?
    let address: String?
    let createdAt: Date?

    init(_ id: UUID, user: User?) {
        self.id = id
        name = user?.name
        email = user?.email
        role = user?.role
        phone = user?.phone
        address = user?.address
        createdAt = user?.createdAt
    }
}

struct RescheduleAppointmentRequest: Content {
    let date: String
    let time: String
}

struct CancelAppointmentRequest: Content {
    let reason: String
    let note: String?
}

struct DecideCancellationRequest: Content {
    let approved: Bool
}

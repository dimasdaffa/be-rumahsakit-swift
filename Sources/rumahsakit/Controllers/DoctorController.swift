import Vapor
import Fluent
import VaporToOpenAPI

struct DoctorController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let doctors = routes.grouped("api", "doctors")
        
        // ==========================
        // 1. PUBLIC ROUTES
        // ==========================
        doctors.get(use: index)
            .openAPI(summary: "List all doctors (Public Safe Data)")
            
        // ==========================
        // 2. DOCTOR SELF-SERVICE (New!) ✅
        // ==========================
        // NOTE: These routes MUST be registered BEFORE /:id routes
        // to prevent "me" from being matched as an ID parameter
        let doctorGroup = doctors.grouped(CheckRole(requiredRole: .doctor))
        
        doctorGroup.get("me", use: getMe)
            .openAPI(summary: "Get my doctor profile")
            
        doctorGroup.put("me", use: updateMe)
            .openAPI(
                summary: "Update my doctor profile",
                body: .type(UpdateDoctorMyProfileRequest.self)
            )
        
        // ==========================
        // 3. PUBLIC ROUTE WITH ID PARAM
        // ==========================
        doctors.get(":id", use: show)
            .openAPI(summary: "Get doctor details")
        doctors.get(":id", "availability", use: availability).openAPI(summary: "Get bookable slots by date")
        doctors.put(":id", "favorite", use: favorite).openAPI(summary: "Favorite a doctor")
        doctors.delete(":id", "favorite", use: unfavorite).openAPI(summary: "Unfavorite a doctor")
        
        // ==========================
        // 4. ADMIN ONLY ROUTES
        // ==========================
        let admin = doctors.grouped(CheckRole(requiredRole: .admin))
        
        admin.post(use: create)
            .openAPI(
                summary: "Create a new doctor (Admin only)",
                body: .type(CreateDoctorInput.self)
            )
        
        admin.group(":id") { doctor in
            doctor.put(use: update)
                .openAPI(
                    summary: "Update doctor (Admin only)",
                    body: .type(CreateDoctorInput.self)
                )
            
            doctor.delete(use: delete)
                .openAPI(summary: "Delete doctor (Admin only)")
        }
    }

    // GET /api/doctors
    @Sendable
    func index(req: Request) async throws -> [DoctorPublicResponse] {
        let user = try req.auth.require(User.self)
        let search = req.query[String.self, at: "q"]?.trimmingCharacters(in: .whitespacesAndNewlines)
        let specialty = req.query[String.self, at: "specialty"]
        let favorites = try await DoctorFavorite.query(on: req.db).filter(\.$userId == user.requireID()).all()
        let favoriteIds = Set(favorites.map(\.doctorId))
        let favoritesOnly = req.query[Bool.self, at: "favorites"] == true
        let doctors = try await Doctor.query(on: req.db).sort(\.$name).all().filter { doctor in
            let matchesSearch = search.map { $0.isEmpty || doctor.name.localizedCaseInsensitiveContains($0) || doctor.specialty.localizedCaseInsensitiveContains($0) } ?? true
            let matchesSpecialty = specialty.map { doctor.specialty.caseInsensitiveCompare($0) == .orderedSame } ?? true
            return matchesSearch && matchesSpecialty && (!favoritesOnly || favoriteIds.contains(doctor.id!))
        }
        guard !doctors.isEmpty else { return [] }

        let now = Date()
        let calendar = ClinicTime.calendar
        let today = calendar.startOfDay(for: now)
        let days = (0..<14).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        let doctorIds = try doctors.map { try $0.requireID() }
        let schedules = try await Schedule.query(on: req.db).filter(\.$doctor.$id ~~ doctorIds).all()
        let appointments = try await Appointment.query(on: req.db).filter(\.$doctor.$id ~~ doctorIds)
            .filter(\.$date >= ClinicTime.dayString(today)).filter(\.$date <= ClinicTime.dayString(days.last!))
            .filter(\.$status ~~ BookingSlots.occupyingStatuses).all()
        let schedulesByDoctor = Dictionary(grouping: schedules, by: { $0.$doctor.id })
        let appointmentsByDoctor = Dictionary(grouping: appointments, by: { $0.$doctor.id })

        return doctors.map { doctor in
            let id = doctor.id!
            let next = days.lazy.compactMap { day in
                BookingSlots.slots(on: day, schedules: schedulesByDoctor[id] ?? [], appointments: appointmentsByDoctor[id] ?? [], now: now)
                    .first(where: \.available)
            }.first
            return DoctorPublicResponse(doctor, isFavorite: favoriteIds.contains(id), nextAvailable: next)
        }
    }

    @Sendable
    func show(req: Request) async throws -> DoctorPublicResponse {
        let user = try req.auth.require(User.self)
        let doctorId = try req.parameters.require("id", as: UUID.self)
        guard let doctor = try await Doctor.find(doctorId, on: req.db) else { throw Abort(.notFound) }
        let favorite = try await DoctorFavorite.query(on: req.db)
            .filter(\.$userId == user.requireID()).filter(\.$doctorId == doctorId).first()
        return DoctorPublicResponse(doctor, isFavorite: favorite != nil)
    }

    @Sendable
    func availability(req: Request) async throws -> [AppointmentSlot] {
        let id = try req.parameters.require("id", as: UUID.self)
        guard try await Doctor.find(id, on: req.db) != nil else { throw Abort(.notFound) }
        let range = try req.query.decode(AvailabilityQuery.self)
        guard let from = ClinicTime.day(range.from), let to = ClinicTime.day(range.to),
              let length = ClinicTime.calendar.dateComponents([.day], from: from, to: to).day,
              (0..<31).contains(length) else {
            throw Abort(.badRequest, reason: "Provide from and to dates covering up to 31 days")
        }
        let now = Date()
        let schedules = try await Schedule.query(on: req.db).filter(\.$doctor.$id == id).all()
        let appointments = try await Appointment.query(on: req.db).filter(\.$doctor.$id == id)
            .filter(\.$date >= range.from).filter(\.$date <= range.to)
            .filter(\.$status ~~ BookingSlots.occupyingStatuses).all()
        return (0...length).compactMap { ClinicTime.calendar.date(byAdding: .day, value: $0, to: from) }
            .flatMap { BookingSlots.slots(on: $0, schedules: schedules, appointments: appointments, now: now) }
    }

    @Sendable
    func favorite(req: Request) async throws -> HTTPStatus {
        let userId = try req.auth.require(User.self).requireID()
        let doctorId = try req.parameters.require("id", as: UUID.self)
        try await req.db.transaction { database in
            try await BookingSlots.lockDoctor(doctorId, on: database)
            if try await DoctorFavorite.query(on: database).filter(\.$userId == userId).filter(\.$doctorId == doctorId).first() == nil {
                let favorite = DoctorFavorite()
                favorite.userId = userId
                favorite.doctorId = doctorId
                try await favorite.create(on: database)
            }
        }
        return .noContent
    }

    @Sendable
    func unfavorite(req: Request) async throws -> HTTPStatus {
        let userId = try req.auth.require(User.self).requireID()
        let doctorId = try req.parameters.require("id", as: UUID.self)
        try await DoctorFavorite.query(on: req.db).filter(\.$userId == userId).filter(\.$doctorId == doctorId).delete()
        return .noContent
    }

    // POST /api/doctors (Admin Only)
    @Sendable
    func create(req: Request) async throws -> Doctor {
        let input = try req.content.decode(CreateDoctorInput.self) // Uses DTO from separate file
        
        if let _ = try await User.query(on: req.db).filter(\.$email == input.email).first() {
            throw Abort(.conflict, reason: "Email already registered as a User")
        }

        let password = input.password ?? "password123"
        let passwordHash = try Bcrypt.hash(password)
        
        let newUser = User(
            name: input.name,
            email: input.email,
            passwordHash: passwordHash,
            role: .doctor
        )
        newUser.phone = input.phone
        try await newUser.save(on: req.db)
        
        let doctor = Doctor(
            userId: newUser.id!,
            name: input.name,
            email: input.email,
            phone: input.phone,
            specialty: input.specialty,
            status: input.status,
            license: input.license,
            experience: input.experience,
            education: input.education,
            bio: input.bio,
            joinDate: input.joinDate,
            totalPatients: input.totalPatients,
            rating: input.rating
        )
        
        doctor.avatarURL = input.avatarURL
        doctor.reviewCount = input.reviewCount
        doctor.practice = input.practice
        try await doctor.save(on: req.db)
        return doctor
    }

    // PUT /api/doctors/:id
    @Sendable
    func update(req: Request) async throws -> Doctor {
        guard let doctor = try await Doctor.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let input = try req.content.decode(CreateDoctorInput.self)
        
        doctor.name = input.name
        doctor.email = input.email
        doctor.phone = input.phone
        doctor.specialty = input.specialty
        doctor.status = input.status
        doctor.license = input.license
        doctor.experience = input.experience
        doctor.education = input.education
        doctor.bio = input.bio
        doctor.joinDate = input.joinDate
        doctor.totalPatients = input.totalPatients
        doctor.rating = input.rating
        if let avatarURL = input.avatarURL { doctor.avatarURL = avatarURL }
        if let reviewCount = input.reviewCount { doctor.reviewCount = reviewCount }
        if let practice = input.practice { doctor.practice = practice }
        
        try await doctor.save(on: req.db)
        
        if let user = try await User.find(doctor.$user.id, on: req.db) {
            user.email = input.email
            user.name = input.name
            user.phone = input.phone
            try await user.save(on: req.db)
        }
        
        return doctor
    }

    // DELETE /api/doctors/:id
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let doctor = try await Doctor.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        try await doctor.delete(on: req.db)
        return .noContent
    }

    // MARK: - New Handlers
    
    // GET /api/doctors/me
    @Sendable
    func getMe(req: Request) async throws -> DoctorPublicResponse {
        let user = try req.auth.require(User.self)
        
        // Find the Doctor profile linked to this User
        guard let doc = try await Doctor.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .first() else {
            throw Abort(.notFound, reason: "Doctor profile not found for this user")
        }
        
        // Return Safe DTO
        return DoctorPublicResponse(doc)
    }
    
    // PUT /api/doctors/me
    @Sendable
    func updateMe(req: Request) async throws -> DoctorPublicResponse {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(UpdateDoctorMyProfileRequest.self)
        
        // Find Profile
        guard let doc = try await Doctor.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .first() else {
            throw Abort(.notFound, reason: "Doctor profile not found")
        }
        
        // Update Fields
        if let p = input.phone { doc.phone = p }
        if let s = input.specialty { doc.specialty = s }
        if let st = input.status { doc.status = st }
        if let e = input.education { doc.education = e }
        if let b = input.bio { doc.bio = b }
        if let ex = input.experience { doc.experience = ex }
        if let avatarURL = input.avatarURL { doc.avatarURL = avatarURL }
        if let practice = input.practice { doc.practice = practice }
        
        try await doc.save(on: req.db)
        
        return DoctorPublicResponse(doc)
    }
}
private struct AvailabilityQuery: Content {
    let from: String
    let to: String
}

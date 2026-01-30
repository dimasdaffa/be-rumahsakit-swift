import Vapor
import Fluent
import VaporToOpenAPI

struct DoctorController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let doctors = routes.grouped("api", "doctors")
        
        // ✅ PUBLIC ROUTES
        doctors.get(use: index)
            .openAPI(summary: "List all doctors (Public Safe Data)")
        
        doctors.get(":id", use: show)
            .openAPI(summary: "Get doctor details")
        
        // 🔒 ADMIN ONLY ROUTES
        let admin = doctors.grouped(CheckRole(requiredRole: .admin))
        
        admin.post(use: create)
            .openAPI(
                summary: "Create a new doctor (Admin only)",
                body: .type(CreateDoctorInput.self) // Defines input schema
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
        let doctors = try await Doctor.query(on: req.db).all()
        return doctors.map { doc in
            DoctorPublicResponse(
                id: doc.id!,
                name: doc.name,
                specialty: doc.specialty,
                status: doc.status,
                experience: doc.experience,
                rating: doc.rating,
                bio: doc.bio,
                education: doc.education,
                license: doc.license
            )
        }
    }

    // GET /api/doctors/:id
    @Sendable
    func show(req: Request) async throws -> DoctorPublicResponse {
        guard let doc = try await Doctor.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        return DoctorPublicResponse(
            id: doc.id!,
            name: doc.name,
            specialty: doc.specialty,
            status: doc.status,
            experience: doc.experience,
            rating: doc.rating,
            bio: doc.bio,
            education: doc.education,
            license: doc.license
        )
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
}
import Vapor
import Fluent
import VaporToOpenAPI

// Update Input to include password
struct CreateDoctorInput: Content {
    var name: String
    var email: String
    var password: String? // Optional: If empty, use default "password123"
    var phone: String
    var specialty: String
    var status: String
    var license: String?
    var experience: Int
    var education: String?
    var bio: String?
    var joinDate: String?
    var totalPatients: Int
    var rating: Double
}

struct DoctorController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let doctors = routes.grouped("api", "doctors")
        
        doctors.get(use: index)
        
        doctors.post(use: create)
            .openAPI(body: .type(CreateDoctorInput.self))
        
        doctors.group(":id") { doctor in
            doctor.get(use: show)
            doctor.put(use: update)
                .openAPI(body: .type(CreateDoctorInput.self))
            doctor.delete(use: delete)
        }
    }

    // GET /api/doctors
    @Sendable
    func index(req: Request) async throws -> [Doctor] {
        return try await Doctor.query(on: req.db).with(\.$user).all()
    }

    // POST /api/doctors
    @Sendable
    func create(req: Request) async throws -> Doctor {
        let input = try req.content.decode(CreateDoctorInput.self)
        
        // 1. Check if email already exists in Users
        if let _ = try await User.query(on: req.db).filter(\.$email == input.email).first() {
            throw Abort(.conflict, reason: "Email already registered as a User")
        }

        // 2. Create the User Account (Login)
        let password = input.password ?? "password123" // Default password
        let passwordHash = try Bcrypt.hash(password)
        
        let newUser = User(
            name: input.name,
            email: input.email,
            passwordHash: passwordHash,
            role: .doctor // Force Role to Doctor
        )
        // Set other profile fields if available
        newUser.phone = input.phone
        
        try await newUser.save(on: req.db)
        
        // 3. Create the Doctor Profile (Linked to User)
        let doctor = Doctor(
            userId: newUser.id!, // Link here!
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

    // GET /api/doctors/:id
    @Sendable
    func show(req: Request) async throws -> Doctor {
        guard let doctor = try await Doctor.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        return doctor
    }

    // PUT /api/doctors/:id
    @Sendable
    func update(req: Request) async throws -> Doctor {
        guard let doctor = try await Doctor.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        let input = try req.content.decode(CreateDoctorInput.self)
        
        // Update Doctor Fields
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
        
        // Optional: Also update the User email/name to keep them in sync
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
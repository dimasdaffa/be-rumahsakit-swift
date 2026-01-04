import Vapor
import Fluent
import VaporToOpenAPI

// DTO for creating/updating doctors - tells Swagger what fields are expected
struct CreateDoctorInput: Content {
    var name: String
    var email: String
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
        
        // POST with documented request body
        doctors.post(use: create)
            .openAPI(body: .type(CreateDoctorInput.self))
        
        doctors.group(":id") { doctor in
            doctor.get(use: show)
            
            // PUT with documented request body
            doctor.put(use: update)
                .openAPI(body: .type(CreateDoctorInput.self))
            
            doctor.delete(use: delete)
        }
    }

    // GET /api/doctors
    @Sendable
    func index(req: Request) async throws -> [Doctor] {
        // Fetch all doctors from MySQL
        return try await Doctor.query(on: req.db).all()
    }

    // POST /api/doctors
    @Sendable
    func create(req: Request) async throws -> Doctor {
        // Decode JSON -> CreateDoctorInput
        let input = try req.content.decode(CreateDoctorInput.self)
        
        // Create Doctor from input
        let doctor = Doctor(
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
        
        // Save to MySQL
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
        // 1. Find the doctor
        guard let doctor = try await Doctor.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // 2. Decode the new data
        let input = try req.content.decode(CreateDoctorInput.self)
        
        // 3. Update fields
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
        
        // 4. Save changes
        try await doctor.save(on: req.db)
        
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
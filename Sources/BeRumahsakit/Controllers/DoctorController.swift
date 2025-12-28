import Vapor

// 1. THE SECURE STORE (ACTOR)
actor DoctorStore {
    static let shared = DoctorStore()
    
    // Mock Data with full details
    private var doctors: [Doctor] = [
        Doctor(
            id: "doctor_001",
            name: "Dr. Ahmad Santoso",
            email: "ahmad.santoso@hospital.com",
            phone: "+62 812-3456-7890",
            specialty: "Kardiologi",
            status: "active",
            license: "STR-001-2024",
            experience: 10,
            education: "Universitas Indonesia - Spesialis Jantung",
            bio: "Ahli kardiologi berpengalaman dengan fokus pada pencegahan.",
            joinDate: "2020-01-15",
            totalPatients: 150,
            rating: 4.8
        ),
        Doctor(
            id: "doctor_002",
            name: "Dr. Siti Rahayu",
            email: "siti.rahayu@hospital.com",
            phone: "+62 813-4567-8901",
            specialty: "Penyakit Dalam",
            status: "active",
            license: "STR-002-2024",
            experience: 8,
            education: "UGM - Spesialis Penyakit Dalam",
            bio: "Fokus pada diabetes dan hipertensi.",
            joinDate: "2021-03-20",
            totalPatients: 120,
            rating: 4.7
        )
    ]
    
    func getAll() -> [Doctor] { return doctors }
    
    func add(_ doctor: Doctor) { doctors.append(doctor) }
    
    func get(id: String) -> Doctor? { return doctors.first(where: { $0.id == id }) }
    
    func update(id: String, updatedDoctor: Doctor) -> Bool {
        if let index = doctors.firstIndex(where: { $0.id == id }) {
            doctors[index] = updatedDoctor
            return true
        }
        return false
    }
    
    func delete(id: String) -> Bool {
        if let index = doctors.firstIndex(where: { $0.id == id }) {
            doctors.remove(at: index)
            return true
        }
        return false
    }
}

// 2. THE CONTROLLER
struct DoctorController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let doctorsGroup = routes.grouped("api", "doctors")
        
        doctorsGroup.get(use: index)
        doctorsGroup.post(use: create)
        doctorsGroup.group(":id") { doctor in
            doctor.get(use: show)
            doctor.put(use: update)
            doctor.delete(use: delete)
        }
    }

    @Sendable
    func index(req: Request) async throws -> [Doctor] {
        return await DoctorStore.shared.getAll()
    }

    @Sendable
    func create(req: Request) async throws -> Doctor {
        var newDoctor = try req.content.decode(Doctor.self)
        
        // Auto-generate ID if missing
        if newDoctor.id == nil { newDoctor.id = UUID().uuidString }
        
        // Set default values
        if newDoctor.totalPatients == nil { newDoctor.totalPatients = 0 }
        if newDoctor.rating == nil { newDoctor.rating = 0.0 }
        if newDoctor.joinDate == nil { 
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            newDoctor.joinDate = formatter.string(from: Date())
        }
        
        await DoctorStore.shared.add(newDoctor)
        return newDoctor
    }

    @Sendable
    func show(req: Request) async throws -> Doctor {
        guard let id = req.parameters.get("id"),
              let doctor = await DoctorStore.shared.get(id: id) else {
            throw Abort(.notFound)
        }
        return doctor
    }

    @Sendable
    func update(req: Request) async throws -> Doctor {
        guard let id = req.parameters.get("id") else { throw Abort(.badRequest) }
        let inputData = try req.content.decode(Doctor.self)
        
        var doctorToSave = inputData
        doctorToSave.id = id
        
        let success = await DoctorStore.shared.update(id: id, updatedDoctor: doctorToSave)
        
        if success {
            return doctorToSave
        } else {
            throw Abort(.notFound)
        }
    }

    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let id = req.parameters.get("id") else { throw Abort(.badRequest) }
        
        let success = await DoctorStore.shared.delete(id: id)
        
        if success {
            return .noContent
        } else {
            throw Abort(.notFound)
        }
    }
}
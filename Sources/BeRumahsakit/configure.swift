import Vapor
import Fluent
import FluentMySQLDriver 
import JWT

public func configure(_ app: Application) async throws {
    // 1. CORS
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration), at: .beginning)
    
    // 2. JWT
    let jwtSecret = Environment.get("JWT_SECRET") ?? "default-secret-change-in-production"
    app.jwt.signers.use(.hs256(key: jwtSecret))

    // 3. DATABASE
    let hostname = Environment.get("DATABASE_HOST") ?? "127.0.0.1"
    let port = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 3306
    let username = Environment.get("DATABASE_USERNAME") ?? "root"
    let password = Environment.get("DATABASE_PASSWORD") ?? "root"
    let database = Environment.get("DATABASE_NAME") ?? "rumahsakit"
    
    app.databases.use(.mysql(
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        database: database
    ), as: .mysql)

    // 4. REGISTER MIGRATIONS 
    app.migrations.add(CreateUser())          // 1. Create Users first
    app.migrations.add(CreateDoctor())        // 2. Doctors link to Users
    app.migrations.add(CreateSchedule())      // 3. Schedules link to Doctors
    app.migrations.add(CreateAppointment())   // 4. Appointments link to both
    app.migrations.add(CreateMedicalRecord()) // 5. Records link to Appointment
    app.migrations.add(SeedAdminUser())

    try routes(app)
}
import Vapor
import Fluent
import FluentMySQLDriver 
import JWT

public func configure(_ app: Application) async throws {
    // 1. CORS (Keep this as is)
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration), at: .beginning)
    // 1. CONFIGURE JWT 🔑
    let jwtSecret = Environment.get("JWT_SECRET") ?? "default-secret-change-in-production"
    app.jwt.signers.use(.hs256(key: jwtSecret))

    // 2. CONNECT TO MYSQL 🐬 - Using environment variables
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

    // 3. REGISTER MIGRATIONS
    app.migrations.add(CreateDoctor())
    app.migrations.add(CreateSchedule())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateAppointment())
    app.migrations.add(CreateMedicalRecord())
    
    // 4. AUTO MIGRATE (commented out - run manually with: swift run rumahsakit migrate)
    // try await app.autoMigrate()

    try routes(app)
}
import Vapor
import Fluent
import FluentMySQLDriver 

public func configure(_ app: Application) async throws {
    // 1. CORS (Keep this as is)
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith]
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration), at: .beginning)

    // 2. CONNECT TO MYSQL 🐬 - Using environment variables
    let hostname = Environment.get("DATABASE_HOST") ?? "127.0.0.1"
    let port = Environment.get("DATABASE_PORT").flatMap(Int.init) ?? 3306
    let username = Environment.get("DATABASE_USERNAME") ?? "root"
    let password = Environment.get("DATABASE_PASSWORD") ?? "root"
    let database = Environment.get("DATABASE_NAME") ?? "rumahsakit"
    
    try app.databases.use(.mysql(
        hostname: hostname,
        port: port,
        username: username,
        password: password,
        database: database
    ), as: .mysql)

    // 3. REGISTER MIGRATIONS (No changes needed here!)
    app.migrations.add(CreateDoctor())
    
    // 4. AUTO MIGRATE
    try await app.autoMigrate()

    try routes(app)
}
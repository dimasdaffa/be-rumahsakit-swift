import Vapor
import VaporToOpenAPI

func routes(_ app: Application) throws {
    
    // ==========================================
    // 1. PUBLIC ROUTES (Open to everyone) 🌍
    // ==========================================
    try app.register(collection: AuthController())
    
    // Swagger Documentation
    app.get("swagger.json") { req in
        app.routes.openAPI(info: InfoObject(title: "RS Permata Sehat API", version: "1.0.0"))
    }
    app.get("api-docs") { req -> Response in
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>API Documentation</title>
            <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui.css" />
        </head>
        <body>
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-bundle.js" crossorigin></script>
            <script>
                window.onload = () => {
                    window.ui = SwaggerUIBundle({
                        url: '/swagger.json', 
                        dom_id: '#swagger-ui',
                    });
                };
            </script>
        </body>
        </html>
        """
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html")
        return Response(status: .ok, headers: headers, body: .init(string: html))
    }

    // ==========================================
    // 2. PROTECTED ROUTES (Must have Token) 🔒
    // ==========================================
    // Users can access these if they are logged in (Doctor, Patient, or Admin)
    let protected = app.grouped(UserAuthenticator())
                       .grouped(User.guardMiddleware())

    // (Add general protected routes here later, like "View My Profile")


    // ==========================================
    // 3. ADMIN ONLY ROUTES (Must be Admin) 👮‍♂️
    // ==========================================
    // ONLY Admins can access these.
    // If a Patient tries to POST here, they get 403 Forbidden.
    let adminOnly = protected.grouped(CheckRole(requiredRole: .admin))
    try protected.register(collection: AppointmentController())
    
    // ⚠️ IMPORTANT: DoctorController & ScheduleController MUST be here!
    // Do NOT register them at the top of the file!
    try adminOnly.register(collection: DoctorController())
    try adminOnly.register(collection: ScheduleController())

    // Appointment Approval Routes
    let appointments = adminOnly.grouped("api", "appointments")
    appointments.put(":id", "approve", use: AppointmentController().approve)
    appointments.put(":id", "reject", use: AppointmentController().reject)
}
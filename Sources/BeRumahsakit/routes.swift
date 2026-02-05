import Vapor
import VaporToOpenAPI

func routes(_ app: Application) throws {
    
    // ==========================================
    // 1. PUBLIC ROUTES (Open to everyone) 🌍
    // ==========================================
    try app.register(collection: AuthController())
    
    // Swagger Documentation (Keep as is)
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
    // All logged-in users (Patient, Doctor, Admin) can access these.
    // The Controllers themselves handle specific permissions internally.
    
    let protected = app.grouped(UserAuthenticator())
                       .grouped(User.guardMiddleware())

    try protected.register(collection: AppointmentController())
    try protected.register(collection: MedicalRecordController())
    try protected.register(collection: UserController())
    try protected.register(collection: ClinicalNoteController())
    try protected.register(collection: DoctorController())
    try protected.register(collection: HealthUpdateController())
    try protected.register(collection: MessageController())
    
    // ✅ MOVED HERE: ScheduleController needs to be accessible by Patients (to view) and Doctors (to edit).
    try protected.register(collection: ScheduleController())

    // ==========================================
    // 3. ADMIN ONLY ROUTES (Must be Admin) 👮‍♂️
    // ==========================================
    let adminOnly = protected.grouped(CheckRole(requiredRole: .admin))
    
    try adminOnly.register(collection: AnalyticsController())

    // Appointment Approval/Rejection Routes
    // (Ideally, move these into AppointmentController logic, but this works for now)
    let appointmentAdmin = adminOnly.grouped("api", "appointments")
    appointmentAdmin.put(":id", "approve", use: AppointmentController().approve)
    appointmentAdmin.put(":id", "reject", use: AppointmentController().reject)
}
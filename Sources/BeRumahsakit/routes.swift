import Vapor
import VaporToOpenAPI

func routes(_ app: Application) throws {
    
    // 1. REGISTER YOUR CONTROLLERS
    try app.register(collection: DoctorController())

    // 2. SWAGGER API (The JSON File)
    app.get("swagger.json") { req in
        // This generates the OpenAPI Spec automatically!
        app.routes.openAPI(
            info: InfoObject(
                title: "RS Bhayangkara Blora API",
                description: "API Documentation for Hospital Management System",
                version: "1.0.0"
            )
        )
    }

    // 3. SWAGGER UI (The Interface)
    // We use a CDN to load the Swagger UI and point it to our JSON
    app.get("api-docs") { req -> Response in
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <title>API Documentation</title>
            <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@4.5.0/swagger-ui.css" />
        </head>
        <body>
            <div id="swagger-ui"></div>
            <script src="https://unpkg.com/swagger-ui-dist@4.5.0/swagger-ui-bundle.js" crossorigin></script>
            <script>
                window.onload = () => {
                    window.ui = SwaggerUIBundle({
                        url: '/swagger.json', // 👈 Points to your JSON route above
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
}
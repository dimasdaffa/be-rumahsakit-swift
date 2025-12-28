import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "RS Bhayangkara API is Running! 🚀"
    }

    // Register the CRUD Controller
    try app.register(collection: DoctorController())
}
import Vapor
import Fluent
import VaporToOpenAPI

struct FileUploadResponse: Content {
    var filename: String
    var url: String
}

struct FileUploadInput: Content {
    var file: File
}

struct FileController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let files = routes.grouped("api", "upload")
        
        // POST /api/upload
        files.on(.POST, body: .collect(maxSize: "5mb"), use: upload)
            .openAPI(
                summary: "Upload a file",
                response: .type(FileUploadResponse.self)
            )
    }

    @Sendable
    func upload(req: Request) async throws -> FileUploadResponse {
        _ = try req.auth.require(User.self) // Only logged-in users
        
        // 1. Decode the file from multipart form-data
        let input = try req.content.decode(FileUploadInput.self, using: FormDataDecoder())
        
        // 2. Validate file size (max 5MB)
        if input.file.data.readableBytes > 5 * 1024 * 1024 {
            throw Abort(.payloadTooLarge, reason: "File size must be under 5MB")
        }
        
        // 3. Generate a safe unique filename
        let originalFilename = input.file.filename
        let fileExtension = originalFilename.split(separator: ".").last.map(String.init) ?? "bin"
        let filename = "\(UUID().uuidString).\(fileExtension)"
        let publicPath = req.application.directory.publicDirectory
        let uploadPath = publicPath + "uploads/"
        
        // 4. Create "Public/uploads" directory if it doesn't exist
        try FileManager.default.createDirectory(atPath: uploadPath, withIntermediateDirectories: true)
        
        // 5. Save the file
        let fullPath = uploadPath + filename
        try await req.fileio.writeFile(input.file.data, at: fullPath)
        
        // 6. Return the URL
        let url = "/uploads/\(filename)"
        
        return FileUploadResponse(filename: filename, url: url)
    }
}
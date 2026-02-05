import Vapor
import Fluent
import VaporToOpenAPI

struct MessageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let messages = routes.grouped("api", "messages")
        
        // LIST MY MESSAGES (Inbox & Sent)
        messages.get(use: index)
            .openAPI(summary: "Get all messages for current user")
        
        // SEND MESSAGE
        messages.post(use: send)
            .openAPI(
                summary: "Send a private message",
                body: .type(SendMessageRequest.self)
            )
            
        // MARK AS READ
        messages.put(":id", "read", use: markAsRead)
            .openAPI(summary: "Mark message as read")
    }

    // GET /api/messages
    @Sendable
    func index(req: Request) async throws -> [MessageResponse] {
        let user = try req.auth.require(User.self)
        
        // Fetch messages where I am Sender OR Receiver
        let messages = try await Message.query(on: req.db)
            .group(.or) { group in
                group.filter(\.$sender.$id == user.id!)
                group.filter(\.$receiver.$id == user.id!)
            }
            .sort(\.$createdAt, .ascending) // Oldest first (like a chat history)
            .with(\.$sender)
            .with(\.$receiver)
            .all()
        
        // Map to Response DTO
        return messages.map { msg in
            MessageResponse(
                id: msg.id!,
                senderId: msg.$sender.id,
                senderName: msg.sender.name,
                receiverId: msg.$receiver.id,
                content: msg.content,
                isRead: msg.isRead,
                createdAt: msg.createdAt
            )
        }
    }

    // POST /api/messages
    @Sendable
    func send(req: Request) async throws -> MessageResponse {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(SendMessageRequest.self)
        
        // Validate Receiver exists
        guard let receiver = try await User.find(input.receiverId, on: req.db) else {
            throw Abort(.notFound, reason: "Receiver user not found")
        }
        
        let message = Message(
            senderId: user.id!,
            receiverId: input.receiverId,
            content: input.content
        )
        
        try await message.save(on: req.db)
        
        // Re-fetch to get eager loaded sender info for the response
        // (Or just construct manually to save a DB call)
        return MessageResponse(
            id: message.id!,
            senderId: user.id!,
            senderName: user.name,
            receiverId: receiver.id!,
            content: message.content,
            isRead: false,
            createdAt: Date()
        )
    }
    
    // PUT /api/messages/:id/read
    @Sendable
    func markAsRead(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let message = try await Message.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Only the RECEIVER can mark it as read
        guard message.$receiver.id == user.id else {
            throw Abort(.forbidden, reason: "You are not the recipient of this message")
        }
        
        message.isRead = true
        try await message.save(on: req.db)
        
        return .ok
    }
}
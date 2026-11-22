import Fluent
import Vapor
import VaporToOpenAPI

struct MessageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let messages = routes.grouped("api", "messages")

        // LIST MY MESSAGES (Inbox & Sent)
        messages.get(use: index)
            .openAPI(summary: "Get all messages for current user")

        messages.get("conversations", use: conversations).openAPI(summary: "List inbox conversations")

        // SEND MESSAGE
        messages.post(use: send)
            .openAPI(
                summary: "Send a private message",
                body: .type(SendMessageRequest.self)
            )

        // MARK AS READ
        messages.put(":id", "read", use: markAsRead)
            .openAPI(summary: "Mark message as read")

        messages.delete(":id", use: delete)
            .openAPI(summary: "Delete a message")
    }

    // GET /api/messages
    @Sendable
    func index(req: Request) async throws -> [MessageResponse] {
        let user = try req.auth.require(User.self)

        let userId = try user.requireID()
        let query = scopedMessages(userId, on: req.db).with(\.$sender)
        if let peerId = req.query[UUID.self, at: "peerId"] {
            query.group(.or) { $0.filter(\.$sender.$id == peerId).filter(\.$receiver.$id == peerId) }
        }
        if let limit = req.query[Int.self, at: "limit"] {
            guard (1...100).contains(limit) else { throw Abort(.badRequest) }
            try applyMessagePage(req, limit: limit, to: query)
            return try await query.sort(\.$createdAt, .descending).sort(\.$id, .descending).all().reversed().map(response)
        }
        return try await query.sort(\.$createdAt).sort(\.$id).all().map(response)
    }

    @Sendable
    func conversations(req: Request) async throws -> [MessageConversation] {
        let userId = try req.auth.require(User.self).requireID()
        let messages = try await scopedMessages(userId, on: req.db)
            .with(\.$sender).with(\.$receiver).sort(\.$createdAt, .descending).sort(\.$id, .descending).all()
        let groups = Dictionary(grouping: messages) { message in
            message.$sender.id == userId ? message.$receiver.id : message.$sender.id
        }
        guard !groups.isEmpty else { return [] }
        let doctors = try await Doctor.query(on: req.db).filter(\.$user.$id ~~ Array(groups.keys)).all()
        let doctorsByUser = Dictionary(grouping: doctors, by: { $0.$user.id })
        let search = req.query[String.self, at: "q"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return groups.compactMap { peerId, thread in
            guard let latest = thread.first else { return nil }
            let peer = latest.$sender.id == userId ? latest.receiver : latest.sender
            let doctor = doctorsByUser[peerId]?.first
            guard search.isEmpty || peer.name.localizedCaseInsensitiveContains(search) ||
                thread.contains(where: { $0.content.localizedCaseInsensitiveContains(search) }) else { return nil }
            return MessageConversation(peerId: peerId, name: peer.name,
                                       specialty: doctor?.specialty ?? (peer.role == .admin ? "Support" : nil),
                                       avatarURL: doctor?.avatarURL ?? peer.avatarURL,
                                       latestMessage: response(latest),
                                       unreadCount: thread.filter { $0.$receiver.id == userId && !$0.isRead }.count)
        }.sorted { ($0.latestMessage.createdAt ?? .distantPast) > ($1.latestMessage.createdAt ?? .distantPast) }
    }

    private func scopedMessages(_ userId: UUID, on db: any Database) -> QueryBuilder<Message> {
        Message.query(on: db).group(.or) { group in
            group.filter(\.$sender.$id == userId).filter(\.$receiver.$id == userId)
        }
    }

    private func applyMessagePage(_ req: Request, limit: Int, to query: QueryBuilder<Message>) throws {
        let page = req.query[Int.self, at: "page"] ?? 1
        guard (1...10_000).contains(page) else { throw Abort(.badRequest) }
        query.range(((page - 1) * limit)..<(page * limit))
    }

    private func response(_ message: Message) -> MessageResponse {
        MessageResponse(id: message.id!, senderId: message.$sender.id, senderName: message.sender.name,
                        receiverId: message.$receiver.id, content: message.content,
                        isRead: message.isRead, createdAt: message.createdAt)
    }

    // POST /api/messages
    @Sendable
    func send(req: Request) async throws -> MessageResponse {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(SendMessageRequest.self)

        guard !input.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              input.content.count <= 255 else { throw Abort(.badRequest, reason: "Message must contain 1–255 characters") }

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

    // DELETE /api/messages/:id
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let message = try await Message.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Logic: Only the SENDER can delete the message (or Admin)
        if user.role != .admin && message.$sender.id != user.id {
            throw Abort(.forbidden, reason: "You can only delete messages you sent")
        }
        
        try await message.delete(on: req.db)
        return .noContent
    }
}

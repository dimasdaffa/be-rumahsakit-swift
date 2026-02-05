import Vapor

struct SendMessageRequest: Content {
    var receiverId: UUID
    var content: String
}

struct MessageResponse: Content {
    var id: UUID
    var senderId: UUID
    var senderName: String
    var receiverId: UUID
    var content: String
    var isRead: Bool
    var createdAt: Date?
}
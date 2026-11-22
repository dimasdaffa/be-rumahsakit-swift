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
struct MessageConversation: Content {
    let peerId: UUID
    let name: String
    let specialty: String?
    let avatarURL: String?
    let latestMessage: MessageResponse
    let unreadCount: Int
}

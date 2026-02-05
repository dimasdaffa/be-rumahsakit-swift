import Vapor
import Fluent

final class Message: Model, Content {
    static let schema = "messages"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "sender_id")
    var sender: User

    @Parent(key: "receiver_id")
    var receiver: User

    @Field(key: "content")
    var content: String

    @Field(key: "is_read")
    var isRead: Bool

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil, senderId: UUID, receiverId: UUID, content: String, isRead: Bool = false) {
        self.id = id
        self.$sender.id = senderId
        self.$receiver.id = receiverId
        self.content = content
        self.isRead = isRead
    }
}
import Vapor
import Fluent

final class SystemAlert: Model, Content {
    static let schema = "system_alerts"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "type")
    var type: String

    @Field(key: "title")
    var title: String

    @Field(key: "message")
    var message: String

    @Field(key: "status")
    var status: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil, type: String, title: String, message: String, status: String = "active") {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.status = status
    }
}
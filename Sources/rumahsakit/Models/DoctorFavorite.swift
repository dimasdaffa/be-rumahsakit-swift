import Fluent
import Vapor

final class DoctorFavorite: Model, @unchecked Sendable {
    static let schema = "doctor_favorites"

    @ID(key: .id) var id: UUID?
    @Field(key: "user_id") var userId: UUID
    @Field(key: "doctor_id") var doctorId: UUID

    init() {}
}

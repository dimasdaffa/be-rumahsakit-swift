import Vapor

struct HealthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("health", use: check)
    }

    @Sendable
    func check(req: Request) async throws -> HealthCheckResponse {
        let nodeName = Environment.get("NODE_NAME") ?? "unknown-node"
        let formatter = ISO8601DateFormatter()

        return HealthCheckResponse(
            status: "healthy",
            node: nodeName,
            timestamp: formatter.string(from: Date())
        )
    }
}
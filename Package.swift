// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "rumahsakit",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-mysql-driver.git", from: "4.0.0"),
        .package(url: "https://github.com/dankinsoid/VaporToOpenAPI.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "rumahsakit",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMySQLDriver", package: "fluent-mysql-driver"),
                .product(name: "VaporToOpenAPI", package: "VaporToOpenAPI"),
                .product(name: "JWT", package: "jwt")
            ]
        ),
        .testTarget(
            name: "rumahsakitTests",
            dependencies: [
                .target(name: "rumahsakit"),
                .product(name: "VaporTesting", package: "vapor"),
            ]
        )
    ]
)

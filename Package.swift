// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PetApp",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(
            name: "PetApp",
            targets: ["PetApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "PetApp",
            dependencies: [],
            path: "PetApp"
        ),
        .testTarget(
            name: "PetAppTests",
            dependencies: ["PetApp"],
            path: "Tests"
        )
    ]
)

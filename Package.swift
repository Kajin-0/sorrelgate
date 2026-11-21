// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sorrelgate",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SorrelgateCore", targets: ["SorrelgateCore"])
    ],
    targets: [
        .target(
            name: "SorrelgateCore",
            resources: [.process("Resources")],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(
            name: "SorrelgateCoreTests",
            dependencies: ["SorrelgateCore"]
        )
    ]
)

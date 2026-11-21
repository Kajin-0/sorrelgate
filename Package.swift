// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Sorrelgate",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/CoreOffice/CoreXLSX.git", exact: "0.14.2"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.11")
    ],
    products: [
        .library(name: "SorrelgateCore", targets: ["SorrelgateCore"])
    ],
    targets: [
        .target(
            name: "SorrelgateCore",
            dependencies: [
                .product(name: "CoreXLSX", package: "CoreXLSX"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            resources: [.process("Resources")],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .testTarget(
            name: "SorrelgateCoreTests",
            dependencies: ["SorrelgateCore"]
        )
    ]
)

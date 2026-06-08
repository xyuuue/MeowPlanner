// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MeowPlanner",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "MeowPlannerCore", targets: ["MeowPlannerCore"]),
        .executable(name: "MeowPlanner", targets: ["MeowPlannerApp"])
    ],
    targets: [
        .target(
            name: "MeowPlannerCore",
            path: "Sources/MeowPlannerCore"
        ),
        .executableTarget(
            name: "MeowPlannerApp",
            dependencies: ["MeowPlannerCore"],
            path: "Sources/MeowPlannerApp",
            resources: [
                .copy("../../Resources/FuFu"),
                .copy("../../Resources/AppIcon")
            ]
        ),
        .target(
            name: "MeowPlannerWidget",
            dependencies: ["MeowPlannerCore"],
            path: "Sources/MeowPlannerWidget",
            resources: [
                .copy("../../Resources/FuFu")
            ]
        ),
        .testTarget(
            name: "MeowPlannerCoreTests",
            dependencies: ["MeowPlannerCore"],
            path: "Tests/MeowPlannerCoreTests"
        )
    ]
)

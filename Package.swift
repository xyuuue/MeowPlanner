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
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.14.0")
    ],
    targets: [
        .target(
            name: "MeowPlannerCore",
            path: "Sources/MeowPlannerCore"
        ),
        .executableTarget(
            name: "MeowPlannerApp",
            dependencies: [
                "MeowPlannerCore",
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: "Sources/MeowPlannerApp",
            resources: [
                .copy("../../Config/GoogleService-Info.plist"),
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

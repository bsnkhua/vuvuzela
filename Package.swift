// swift-tools-version: 6.0
import PackageDescription

// Tests require splitting into library + executable (like mole-widget).
// Will be added in a follow-up PR.
let package = Package(
    name: "Vuvuzela",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Vuvuzela", targets: ["Vuvuzela"]),
    ],
    targets: [
        .executableTarget(
            name: "Vuvuzela",
            path: "Sources/Vuvuzela",
            resources: [],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)

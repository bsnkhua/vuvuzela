// swift-tools-version: 6.0
import PackageDescription

// Tests require splitting into library + executable (like mole-widget).
// Will be added in a follow-up PR.
let package = Package(
    name: "FIFAWidget",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "FIFAWidget", targets: ["FIFAWidget"]),
    ],
    targets: [
        .executableTarget(
            name: "FIFAWidget",
            path: "Sources/FIFAWidget",
            resources: [],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)

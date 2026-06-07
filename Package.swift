// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Vuvuzela",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "VuvuzelaCore", targets: ["VuvuzelaCore"]),
        .executable(name: "Vuvuzela", targets: ["Vuvuzela"]),
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "VuvuzelaCore",
            path: "Sources/VuvuzelaCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .executableTarget(
            name: "Vuvuzela",
            dependencies: [
                "VuvuzelaCore",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Sources/Vuvuzela",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "VuvuzelaTests",
            dependencies: ["VuvuzelaCore"],
            path: "Tests/VuvuzelaTests",
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .unsafeFlags(["-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"]),
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker", "-rpath",
                    "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/usr/lib",
                ])
            ]
        ),
    ]
)

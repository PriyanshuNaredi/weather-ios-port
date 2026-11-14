// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WeatheriOS",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // An xtool project should contain exactly one library product,
        // representing the main app.
        .library(
            name: "WeatheriOS",
            targets: ["WeatheriOS"]
        ),
    ],
    targets: [
        .target(
            name: "WeatheriOS",
            // Bundled legal texts for the licenses dialog (SettingsScreenView).
            resources: [.copy("legal")]
        ),
    ]
)

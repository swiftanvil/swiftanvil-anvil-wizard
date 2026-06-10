// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AnvilWizard",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "AnvilWizard", targets: ["AnvilWizard"])
    ],
    targets: [
        .target(name: "AnvilWizard"),
        .testTarget(name: "AnvilWizardTests", dependencies: ["AnvilWizard"])
    ],
    swiftLanguageModes: [.v6]
)

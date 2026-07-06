// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "TUISuite",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "TUISuite",
            targets: ["TUISuite"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "TextEditor",
            dependencies: ["TUISuite"],
            path: "Sources/Examples/TextEditor"
        ),
        .target(
            name: "TUISuite"
        ),
        .testTarget(
            name: "TUISuiteTests",
            dependencies: ["TUISuite"]
        ),
    ]
)

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TUISuite",
    products: [
        .library(
            name: "TUISuite",
            targets: ["TUISuite"]
        ),
    ],
    targets: [
        .target(
            name: "TUISuite"
        ),
        .testTarget(
            name: "TUISuiteTests",
            dependencies: ["TUISuite"]
        ),
    ]
)

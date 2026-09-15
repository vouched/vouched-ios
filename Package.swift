// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Vouched",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Vouched",
            targets: ["Vouched"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/DataDog/dd-sdk-ios", .upToNextMinor(from: "3.10.0")),
        .package(url: "https://github.com/Scandit/datacapture-spm", .upToNextMinor(from: "8.2.1")),
        .package(url: "https://github.com/aws-amplify/amplify-ui-swift-liveness", .upToNextMinor(from: "1.4.4")),
        .package(url: "https://github.com/aws-amplify/amplify-swift", .upToNextMinor(from: "2.54.1")),
    ],
    targets: [
        .target(
            name: "Vouched",
            dependencies: [
                "VouchedCore",
                "VouchedScandit",
                "VouchedAmplify",
                .product(name: "DatadogCore", package: "dd-sdk-ios"),
                .product(name: "DatadogLogs", package: "dd-sdk-ios"),
                .product(name: "DatadogRUM", package: "dd-sdk-ios"),
                .product(name: "DatadogCrashReporting", package: "dd-sdk-ios"),
            ],
            path: "Sources/Vouched",
            resources: [.copy("Resources/fonts")]
        ),
        .target(
            name: "VouchedScandit",
            dependencies: [
                .product(name: "ScanditCaptureCore", package: "datacapture-spm"),
                .product(name: "ScanditIdCapture", package: "datacapture-spm"),
                .product(name: "ScanditIDC", package: "datacapture-spm"),
                .product(name: "ScanditBarcodeCapture", package: "datacapture-spm"),
            ],
            path: "Sources/VouchedScandit"
        ),
        .target(
            name: "VouchedAmplify",
            dependencies: [
                .product(name: "FaceLiveness", package: "amplify-ui-swift-liveness"),
                .product(name: "AWSPluginsCore", package: "amplify-swift"),
            ],
            path: "Sources/VouchedAmplify"
        ),
        .binaryTarget(
            name: "VouchedCore",
            url: "https://github.com/vouched/vouched-ios/releases/download/v2.0.0/VouchedCore.xcframework.zip",
            checksum: "d449c3a124ea29cec44d4f92c90ccc06d5ff37dc35615ecd32ff010451e26bfa"
        ),
    ]
)

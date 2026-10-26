// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalSendIOS",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LocalSendIOS",
            targets: ["LocalSendIOS"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LocalSendIOS",
            path: ".",
            exclude: ["Info.plist"]
        )
    ]
)

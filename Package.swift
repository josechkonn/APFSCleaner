// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "APFSCleaner",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "APFSCleaner",
            targets: ["APFSCleaner"]
        )
    ],
    targets: [
        .executableTarget(
            name: "APFSCleaner",
            path: "Sources"
        )
    ]
)

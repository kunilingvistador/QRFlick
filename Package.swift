// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "ScreenQR", platforms: [.macOS(.v14)], products: [.executable(name: "ScreenQR", targets: ["ScreenQR"])], targets: [.executableTarget(name: "ScreenQR")])

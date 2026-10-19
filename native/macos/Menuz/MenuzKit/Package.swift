// swift-tools-version: 6.2
// MenuzKit: everything in Menuz.app that needs no AppKit (ST0027 WP-03), so
// `swift test` runs it without an Xcode build. The app links it through
// project.yml. Yams is the one package (D2). Its floor is the app's, macOS
// 26, which tools version 6.2 is the first to name (issue 0073).
import PackageDescription

let package = Package(
  name: "MenuzKit",
  platforms: [.macOS(.v26)],
  products: [
    .library(name: "MenuzKit", targets: ["MenuzKit"])
  ],
  dependencies: [
    .package(url: "https://github.com/jpsim/Yams", from: "6.0.1")
  ],
  targets: [
    .target(name: "MenuzKit", dependencies: ["Yams"]),
    .testTarget(name: "MenuzKitTests", dependencies: ["MenuzKit"]),
  ]
)

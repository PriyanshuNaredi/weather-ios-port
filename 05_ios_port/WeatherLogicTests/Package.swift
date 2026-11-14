// swift-tools-version:6.0
// WeatherLogicTests — Linux-host test package for Foundation-only logic.
// Shared pure-logic sources are copied from WeatheriOS by 07_tools/logic-tests.sh
// (single source of truth remains 05_ios_port/WeatheriOS/Sources/WeatheriOS).
// NOTE: these tests run on the Linux Swift host against Foundation; they are NOT
// iOS runtime tests and do not exercise SwiftUI/MapKit code paths.
import PackageDescription

let package = Package(
    name: "WeatherLogicTests",
    targets: [
        .target(name: "WeatherLogic", path: "Sources/WeatherLogic"),
        .testTarget(name: "WeatherLogicTests", dependencies: ["WeatherLogic"], path: "Tests/WeatherLogicTests")
    ]
)

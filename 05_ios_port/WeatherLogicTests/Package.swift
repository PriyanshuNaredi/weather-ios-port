// swift-tools-version:6.0
// WeatherLogicTests — Linux-host test package for Foundation-only logic.
// Shared pure-logic sources are copied from WeatheriOS by 07_tools/logic-tests.sh
// (single source of truth remains 05_ios_port/WeatheriOS/Sources/WeatheriOS).
// NOTE: these tests run on the Linux Swift host against Foundation; they are NOT
// iOS runtime tests and do not exercise SwiftUI/MapKit code paths.
import PackageDescription

let package = Package(
    name: "WeatherLogicTests",
    // macOS host runs: without a deployment target SwiftPM defaults to macOS
    // 10.13 and rejects APIs the shared sources legitimately use (e.g.
    // FileHandle.write(contentsOf:) in DiagLog). The Linux toolchain did not care.
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "WeatherLogic", path: "Sources/WeatherLogic"),
        .testTarget(name: "WeatherLogicTests", dependencies: ["WeatherLogic"], path: "Tests/WeatherLogicTests")
    ],
    // macOS note: the shared sources are compiled by the app target in Swift 5
    // language mode (see 05_ios_port/WeatheriOS/project.yml). This package uses
    // tools-version 6.0, which defaults to Swift 6 mode and turns two shared
    // sources' strict-concurrency warnings into errors (DiagLog's
    // `mach_task_self_` read, WeatherMapView's `inFlight` mutation). Pin the same
    // mode here so the host suite exercises the code exactly as it ships.
    swiftLanguageModes: [.v5]
)

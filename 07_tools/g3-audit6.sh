#!/bin/bash
set -u
B="$HOME/.swiftpm/swift-sdks/darwin.artifactbundle"
IOS="$B/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
echo "== SwiftUI.swiftmodule contents (arch slices) =="
ls -la "$IOS/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule"
echo; echo "== MapKit module =="
ls "$IOS/System/Library/Frameworks/MapKit.framework/Modules/MapKit.swiftmodule"
echo; echo "== SDK platform/version string =="
ls "$B/Developer/Platforms" -1
echo "SDK dir names => iPhoneOS27.2 / iPhoneSimulator27.2 / MacOSX27.2 (iOS SDK 27.2)"
echo; echo "== swift-driver discovery test (read-only) =="
D="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04"
"$D/usr/bin/swift" --version
echo; echo "== iOS swiftinterface presence (source-level API check possible) =="
ls "$IOS/System/Library/Frameworks/MapKit.framework/Modules/MapKit.swiftmodule" | head
find "$IOS/System/Library/Frameworks/SwiftUI.framework/Modules" -name '*.swiftinterface' | head -3
find "$IOS/System/Library/Frameworks/CoreLocation.framework" -maxdepth 3 | head

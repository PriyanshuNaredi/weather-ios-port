#!/bin/bash
set -u
B="$HOME/.swiftpm/swift-sdks/darwin.artifactbundle"
IOS="$B/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
SIM="$B/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk"
echo "== key frameworks in iPhoneOS SDK =="
for fw in UIKit SwiftUI MapKit CoreLocation Foundation Combine CoreGraphics WeatherKit CoreText QuartzCore; do
  d="$IOS/System/Library/Frameworks/$fw.framework"
  [ -e "$d" ] && echo "iPhoneOS: $fw FOUND ($(du -sh "$d" | cut -f1))" || echo "iPhoneOS: $fw MISSING"
done
echo; echo "== swiftmodule for SwiftUI/UIKit/MapKit =="
find "$IOS/System/Library/Frameworks/SwiftUI.framework" "$IOS/System/Library/Frameworks/MapKit.framework" "$IOS/System/Library/Frameworks/UIKit.framework" -name '*.swiftmodule' -o -name 'Modules' -maxdepth 2 2>/dev/null | head
ls "$IOS/System/Library/Frameworks/SwiftUI.framework/Modules" 2>/dev/null
ls "$IOS/System/Library/Frameworks/UIKit.framework/Modules" 2>/dev/null
echo; echo "== simulator framework counts =="
echo "sim .framework dirs: $(find "$SIM/System/Library" -type d -name '*.framework' 2>/dev/null | wc -l)"
ls "$SIM/System/Library/Frameworks" 2>/dev/null | head -5
echo; echo "== SDKSettings Version =="
plutil -p "$IOS/SDKSettings.plist" 2>/dev/null | head -20 || strings "$IOS/SDKSettings.plist" | grep -A1 Version
echo; echo "== SDK headers present? =="
ls "$IOS/System/Library/Frameworks/UIKit.framework/Headers" 2>/dev/null | head -5
ls "$IOS/usr/include" 2>/dev/null | head -10
echo; echo "== swift sdk list (host toolchain) =="
export PATH="$HOME/../usr/bin:$PATH"
D="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04"
"$D/usr/bin/swift" sdk list
echo; echo "== origin: does the Swift toolchain bundle this artifactbundle? =="
find "/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04" -name '*.artifactbundle' -maxdepth 4 2>/dev/null
tar -tzf "/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/07_tools/swift-linux/swift-6.4.2-RELEASE-ubuntu26.04.tar.gz" | grep -iE 'darwin|artifactbundle' | head -10

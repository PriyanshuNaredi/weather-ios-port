#!/bin/bash
set -u
B="$HOME/.swiftpm/swift-sdks/darwin.artifactbundle"
echo "== info.json =="; cat "$B/info.json"
echo; echo "== darwin-sdk-version.txt =="; cat "$B/darwin-sdk-version.txt"
echo; echo "== swift-sdk.json =="; cat "$B/swift-sdk.json"
echo; echo "== toolset.json =="; cat "$B/toolset.json"
echo; echo "== toolset-swb.json =="; cat "$B/toolset-swb.json"
echo; echo "== SDK dirs =="
ls "$B/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/" 2>/dev/null
ls "$B/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/" 2>/dev/null
echo; echo "== iPhoneOS SDK version files =="
for f in "$B"/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk/SDKSettings.plist; do
  [ -e "$f" ] && echo "$f" && strings "$f" | grep -iE 'Version|MinimumOS' | head -10
done
echo; echo "== framework presence =="
for fw in UIKit SwiftUI MapKit CoreLocation Foundation Combine CoreGraphics; do
  for P in iPhoneOS iPhoneSimulator MacOSX; do
    d=$(find "$B/Developer/Platforms/$P.platform" -maxdepth 4 -type d -name "$fw.framework" 2>/dev/null | head -1)
    [ -n "$d" ] && echo "$P: $fw.framework FOUND ($(du -sh "$d" | cut -f1))"
  done
done
echo; echo "== module counts (iPhoneOS SDK) =="
IOS=$(find "$B/Developer/Platforms/iPhoneOS.platform/Developer/SDKs" -maxdepth 1 -type d -name 'iPhoneOS*.sdk' | head -1)
echo "SDK root: $IOS"
echo "total .framework dirs: $(find "$IOS/System/Library" -type d -name '*.framework' 2>/dev/null | wc -l)"
echo "swiftmodule files: $(find "$IOS" -name '*.swiftmodule' 2>/dev/null | wc -l)"
echo; echo "== toolset bin =="
ls -la "$B/toolset/bin" | head -20
echo; echo "== toolset bin/orig =="
ls "$B/toolset/bin/orig" 2>/dev/null | head -20
echo; echo "== usr/bin toolchain utils =="
ls "$B/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin" 2>/dev/null | head -30
echo; echo "== Xcode.app stub =="
find "$B/Xcode.app" -maxdepth 4 | head -20

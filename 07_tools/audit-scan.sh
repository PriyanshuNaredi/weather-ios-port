#!/bin/bash
S="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/00_original/source/Weather"
echo "=== files ==="
find "$S/app/src/main" -name "*.kt" -o -name "AndroidManifest.xml" | sed "s|$S/||"
echo; echo "=== endpoint URLs ==="
grep -rn "https://" "$S/app/src/main/java" | sed "s|$S/app/src/main/java/||"
echo; echo "=== Data.kt: functions/caches/prefs ==="
grep -n -E "fun |class |object |SharedPreferences|AtomicFile|cacheDir|900" "$S/app/src/main/java"/*/Data.kt | head -40
echo; echo "=== MainActivity.kt: screens/nav/location/units ==="
grep -n -E "fun |class |enum |sealed|Pager|NavigationBar|LocationManager|requestLocation|metric|Metric|unit|Unit|search|Search|bottomBar|onBack" "$S/app/src/main/java"/*/MainActivity.kt | head -60
echo; echo "=== Maps.kt: layers/styles ==="
grep -n -E "fun |class |Style|Tile|layer|Layer|radar|Radar|temp|Temp|dark" "$S/app/src/main/java"/*/Maps.kt | head -40
echo; echo "=== Models.kt ==="
cat "$S/app/src/main/java"/*/Models.kt

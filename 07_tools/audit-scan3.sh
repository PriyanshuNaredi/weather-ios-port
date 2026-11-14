#!/bin/bash
J="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/00_original/source/Weather/app/src/main/java/dev/kiankonrad/weather"
echo "=== MainActivity screens/nav/location/search/settings ==="
grep -n -E 'screen==|screen=|when\(screen\)|"map"|"cities"|"settings"|LocationManager|getLastKnownLocation|requestLocation|search\(|debounce|imperial|preferences|showMapPreview' "$J/MainActivity.kt" | head -45
echo; echo "=== Data.kt caching/TTL/endpoints/params ==="
grep -n -E '900|expired|cache|forecast-|air-quality|geocoding|weather-maps|hourly|daily|current=|temperature_unit|models=' "$J/Data.kt" | head -45
echo; echo "=== manifest permissions ==="
grep -n -E "uses-permission|uses-feature" "/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/00_original/source/Weather/app/src/main/AndroidManifest.xml"
echo; echo "=== test files ==="
ls "/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/00_original/source/Weather/app/src/test"/*/

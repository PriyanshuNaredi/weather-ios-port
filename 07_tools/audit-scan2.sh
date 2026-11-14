#!/bin/bash
J="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port/00_original/source/Weather/app/src/main/java/dev/kiankonrad/weather"
echo "=== Data.kt structure ==="
grep -n -E "^(private )?(class|object|data class) |    fun |val CACHE|900|AtomicFile|SharedPreferences|getSharedPreferences|fun get\(" "$J/Data.kt"
echo; echo "=== MainActivity.kt structure ==="
grep -n -E "^(private )?(class|enum|sealed|data) |^fun |    (private )?fun |enum class|HorizontalPager|NavigationBar|LocationManager|requestLocationUpdates|Metric\.|metric|units|screenshot|BottomNav" "$J/MainActivity.kt" | head -50
echo; echo "=== Maps.kt structure ==="
grep -n -E "^(private )?(class|enum|data) |    fun |Style|url|radar|temperature|layer|attribution" "$J/Maps.kt" | head -40

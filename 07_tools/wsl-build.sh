#!/bin/bash
# Build script: runs the Gradle build inside WSL Ubuntu using the portable Linux JDK
# and the portable Android SDK, all inside the project root. No system installs.
# v2: Gradle user-home and project cache moved to WSL ext4 ($HOME/.gradle-weather)
# because the Gradle daemon cannot reliably write registry.bin on /mnt/c (drvfs/9p).
# Artifacts remain readable via the repo build dir; copy APK back into project manually.
set -u
ROOT="/mnt/c/Users/naredi/Downloads/Android Weather APK Reverse Engineering → Native iOS Port"
SRC="$ROOT/00_original/source/Weather"
TOOLS="$ROOT/07_tools"
export JAVA_HOME="$TOOLS/jdk-linux"
export ANDROID_HOME="$TOOLS/android-sdk-linux"
export GRADLE_USER_HOME="$HOME/.gradle-weather"
export PATH="$JAVA_HOME/bin:$PATH"
mkdir -p "$GRADLE_USER_HOME"
CACHE="$HOME/.gradle-weather/project-cache"
mkdir -p "$CACHE"
cd "$SRC" || exit 9
java -version 2>&1 | head -1
if [ ! -d "$ANDROID_HOME/build-tools/37.0.0" ]; then
  yes | java -classpath "$TOOLS/android-sdk/cmdline-tools/latest/lib/*" \
    com.android.sdklib.tool.sdkmanager.SdkManagerCli --sdk_root="$ANDROID_HOME" \
    "platforms;android-37.0" "build-tools;37.0.0" > "$TOOLS/sdkmanager-install-linux.log" 2>&1
  echo "sdkmanager exit=$?"
fi
exec "$JAVA_HOME/bin/java" -classpath gradle/wrapper/gradle-wrapper.jar org.gradle.wrapper.GradleWrapperMain "$@" --project-cache-dir "$CACHE"

#!/bin/bash

echo "==== APK Availability Check ===="

# Check local build folder (if built locally)
echo "Checking local build folder..."
LOCAL_APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
GRADLE_APK_PATH="android/app/build/outputs/apk/debug/app-debug.apk"
GRADLE_CUSTOM_APK_PATH="android/app/build/outputs/apk/debug/CRF_Android_final.apk"

if [ -f "$LOCAL_APK_PATH" ]; then
  echo "✅ Local Flutter APK found at: $LOCAL_APK_PATH"
  APK_SIZE=$(du -h "$LOCAL_APK_PATH" | cut -f1)
  echo "   Size: $APK_SIZE"
elif [ -f "$GRADLE_APK_PATH" ]; then
  echo "✅ Gradle APK found at: $GRADLE_APK_PATH"
  APK_SIZE=$(du -h "$GRADLE_APK_PATH" | cut -f1)
  echo "   Size: $APK_SIZE"
elif [ -f "$GRADLE_CUSTOM_APK_PATH" ]; then
  echo "✅ Custom named Gradle APK found at: $GRADLE_CUSTOM_APK_PATH"
  APK_SIZE=$(du -h "$GRADLE_CUSTOM_APK_PATH" | cut -f1)
  echo "   Size: $APK_SIZE"
else
  echo "❌ No APK found locally."
  echo "   Run 'flutter build apk --debug' to build locally."
fi

echo ""
echo "==== Codemagic APK Download Instructions ===="
echo "1. Go to your Codemagic dashboard: https://codemagic.io/apps"
echo "2. Select your CRF app build"
echo "3. Find the latest successful build"
echo "4. Download the 'CRF_Android_final.apk' artifact"
echo ""
echo "Important file paths in Codemagic build:"
echo "- build/app/outputs/flutter-apk/app-debug.apk"
echo "- android/app/build/outputs/apk/debug/app-debug.apk"
echo "- android/app/build/outputs/apk/debug/CRF_Android_final.apk"
echo "- \$FCI_BUILD_OUTPUT_DIR/CRF_Android_final.apk (downloadable artifact)"
echo ""
echo "If you still don't see the APK, check the build logs for any errors." 
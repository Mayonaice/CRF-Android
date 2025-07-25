Write-Host "==== APK Availability Check ====" -ForegroundColor Cyan

# Check local build folder (if built locally)
Write-Host "Checking local build folder..." -ForegroundColor Yellow
$LOCAL_APK_PATH = "build/app/outputs/flutter-apk/app-debug.apk"
$GRADLE_APK_PATH = "android/app/build/outputs/apk/debug/app-debug.apk"
$GRADLE_CUSTOM_APK_PATH = "android/app/build/outputs/apk/debug/CRF_Android_final.apk"

if (Test-Path $LOCAL_APK_PATH) {
    Write-Host "✅ Local Flutter APK found at: $LOCAL_APK_PATH" -ForegroundColor Green
    $fileInfo = Get-Item $LOCAL_APK_PATH
    $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)
    Write-Host "   Size: $sizeInMB MB" -ForegroundColor Green
} elseif (Test-Path $GRADLE_APK_PATH) {
    Write-Host "✅ Gradle APK found at: $GRADLE_APK_PATH" -ForegroundColor Green
    $fileInfo = Get-Item $GRADLE_APK_PATH
    $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)
    Write-Host "   Size: $sizeInMB MB" -ForegroundColor Green
} elseif (Test-Path $GRADLE_CUSTOM_APK_PATH) {
    Write-Host "✅ Custom named Gradle APK found at: $GRADLE_CUSTOM_APK_PATH" -ForegroundColor Green
    $fileInfo = Get-Item $GRADLE_CUSTOM_APK_PATH
    $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)
    Write-Host "   Size: $sizeInMB MB" -ForegroundColor Green
} else {
    Write-Host "❌ No APK found locally." -ForegroundColor Red
    Write-Host "   Run 'flutter build apk --debug' to build locally." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==== Codemagic APK Download Instructions ====" -ForegroundColor Cyan
Write-Host "1. Go to your Codemagic dashboard: https://codemagic.io/apps" -ForegroundColor White
Write-Host "2. Select your CRF app build" -ForegroundColor White
Write-Host "3. Find the latest successful build" -ForegroundColor White
Write-Host "4. Download the 'CRF_Android_final.apk' artifact" -ForegroundColor Green
Write-Host ""
Write-Host "Important file paths in Codemagic build:" -ForegroundColor Yellow
Write-Host "- build/app/outputs/flutter-apk/app-debug.apk" -ForegroundColor White
Write-Host "- android/app/build/outputs/apk/debug/app-debug.apk" -ForegroundColor White
Write-Host "- android/app/build/outputs/apk/debug/CRF_Android_final.apk" -ForegroundColor White
Write-Host "- `$FCI_BUILD_OUTPUT_DIR/CRF_Android_final.apk (downloadable artifact)" -ForegroundColor Green
Write-Host ""
Write-Host "If you still don't see the APK, check the build logs for any errors." -ForegroundColor Yellow 
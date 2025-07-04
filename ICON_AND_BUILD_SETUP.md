# DCT CRF Android - Icon and Build Setup

## App Name and Icon Changes

### App Name
- **New App Name**: `DCT CRF Android`
- **Previous**: `CRF App`
- **Updated in**: `android/app/src/main/AndroidManifest.xml`

### App Icon
- **Icon Source**: `assets/images/app_icon.png`
- **Previous**: `assets/images/logo.png`
- **Updated in**: `pubspec.yaml`

## Android API 34 Compatibility Updates

### Problem Solved
The `mobile_scanner` package requires Android API level 34, but the project was using API 33. This caused build failures in Codemagic.

### Changes Made
1. **Android Gradle Plugin**: Updated from 7.3.0 to 8.1.0
2. **Kotlin Version**: Updated from 1.7.10 to 1.9.10
3. **Gradle Version**: Updated from 7.4 to 8.0
4. **Compile SDK**: Updated from 33 to 34
5. **Target SDK**: Updated from 33 to 34
6. **Java Version**: Updated from 11 to 17 (required for AGP 8.1.0)

### Updated Files
- `android/build.gradle` - Android Gradle Plugin and Kotlin versions
- `android/app/build.gradle` - Compile and target SDK versions
- `android/gradle.properties` - SDK configuration properties
- `android/gradle/wrapper/gradle-wrapper.properties` - Gradle wrapper version
- `codemagic.yaml` - Java version and build configuration

## Build Configuration

### Codemagic CI/CD Updates
The `codemagic.yaml` file has been updated with:

1. **Java 17 Support**:
   - Updated from Java 11 to Java 17 for Android Gradle Plugin 8.1.0

2. **Proper Icon Handling**:
   - Uses `assets/images/app_icon.png` as the source
   - Converts to all required Android icon sizes (hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)
   - Fallback to copy original PNG if ImageMagick fails

3. **Enhanced Build Process**:
   - Added verification steps for icon generation
   - Improved APK naming with timestamp: `DCT-CRF-Android-debug-YYYYMMDDHHMM.apk`
   - Better error handling and logging

4. **Mobile Scanner Support**:
   - Updated Gradle configuration for `mobile_scanner` package compatibility
   - Added proper camera permissions handling
   - Android API 34 compatibility

### Local Development Scripts

#### For Windows (PowerShell)
```powershell
.\generate_icons.ps1
```

#### For Linux/Mac (Bash)
```bash
chmod +x generate_icons.sh
./generate_icons.sh
```

Both scripts will:
- Check if `assets/images/app_icon.png` exists
- Create required Android icon directories
- Convert icon to all required sizes (or copy if ImageMagick not available)
- Verify generated icons

## Dependencies Added

### pubspec.yaml
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

### Icon Configuration
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/images/app_icon.png"
  adaptive_icon_background: "#0056A4"
  adaptive_icon_foreground: "assets/images/app_icon.png"
  min_sdk_android: 21
```

## Build Commands

### Local Development
```bash
# Generate icons first
./generate_icons.sh  # or .\generate_icons.ps1 on Windows

# Build APK
flutter build apk --debug
```

### Codemagic CI/CD
- Push to repository
- Codemagic will automatically build and generate APK
- APK will be named: `DCT-CRF-Android-debug-YYYYMMDDHHMM.apk`

## File Structure
```
crf-and1/
├── assets/images/app_icon.png          # Main app icon
├── android/
│   ├── build.gradle                    # AGP 8.1.0, Kotlin 1.9.10
│   ├── gradle.properties               # Android API 34 config
│   ├── gradle/wrapper/
│   │   └── gradle-wrapper.properties   # Gradle 8.0
│   └── app/
│       ├── build.gradle                # compileSdk 34, targetSdk 34
│       └── src/main/
│           ├── AndroidManifest.xml     # App name: "DCT CRF Android"
│           └── res/mipmap-*/ic_launcher.png  # Generated icons
├── codemagic.yaml                      # CI/CD with Java 17
├── pubspec.yaml                        # Dependencies and icon config
├── generate_icons.sh                   # Linux/Mac icon generator
├── generate_icons.ps1                  # Windows icon generator
└── ICON_AND_BUILD_SETUP.md            # This documentation
```

## Version Compatibility Matrix

| Component | Version | Reason |
|-----------|---------|---------|
| Android Gradle Plugin | 8.1.0 | Supports Android API 34 |
| Gradle | 8.0 | Compatible with AGP 8.1.0 |
| Java | 17 | Required for AGP 8.1.0 |
| Kotlin | 1.9.10 | Compatible with AGP 8.1.0 |
| Android Compile SDK | 34 | Required by mobile_scanner |
| Android Target SDK | 34 | Required by mobile_scanner |
| Min SDK | 21 | Flutter minimum requirement |

## Troubleshooting

### Icon Not Showing
1. Verify `assets/images/app_icon.png` exists
2. Run icon generation script
3. Check generated icons in `android/app/src/main/res/mipmap-*`
4. Rebuild APK

### Build Fails - API Level Issues
1. Verify Android API 34 configuration in `android/gradle.properties`
2. Check `android/app/build.gradle` has `compileSdkVersion 34`
3. Ensure Java 17 is being used in Codemagic

### Mobile Scanner Issues
1. Check camera permissions in AndroidManifest.xml
2. Verify Android API 34 compatibility
3. Ensure `mobile_scanner: ^3.5.6` is in pubspec.yaml

### Codemagic Build Issues
1. Check build logs for icon generation errors
2. Verify app_icon.png is committed to repository
3. Check Java 17 and Gradle 8.0 compatibility
4. Verify Android API 34 configuration 
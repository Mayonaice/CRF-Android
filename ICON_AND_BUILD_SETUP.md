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

## Build Configuration

### Codemagic CI/CD Updates
The `codemagic.yaml` file has been updated with:

1. **Proper Icon Handling**:
   - Uses `assets/images/app_icon.png` as the source
   - Converts to all required Android icon sizes (hdpi, mdpi, xhdpi, xxhdpi, xxxhdpi)
   - Fallback to copy original PNG if ImageMagick fails

2. **Enhanced Build Process**:
   - Added verification steps for icon generation
   - Improved APK naming with timestamp: `DCT-CRF-Android-debug-YYYYMMDDHHMM.apk`
   - Better error handling and logging

3. **Mobile Scanner Support**:
   - Updated Gradle configuration for `mobile_scanner` package compatibility
   - Added proper camera permissions handling

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
├── android/app/src/main/
│   ├── AndroidManifest.xml             # App name: "DCT CRF Android"
│   └── res/mipmap-*/ic_launcher.png    # Generated icons
├── codemagic.yaml                      # CI/CD configuration
├── pubspec.yaml                        # Dependencies and icon config
├── generate_icons.sh                   # Linux/Mac icon generator
├── generate_icons.ps1                  # Windows icon generator
└── ICON_AND_BUILD_SETUP.md            # This documentation
```

## Troubleshooting

### Icon Not Showing
1. Verify `assets/images/app_icon.png` exists
2. Run icon generation script
3. Check generated icons in `android/app/src/main/res/mipmap-*`
4. Rebuild APK

### Build Fails
1. Check camera permissions in AndroidManifest.xml
2. Ensure `mobile_scanner` dependency is properly configured
3. Verify Gradle configuration in `android/gradle.properties`

### Codemagic Build Issues
1. Check build logs for icon generation errors
2. Verify app_icon.png is committed to repository
3. Check ImageMagick availability in build environment 
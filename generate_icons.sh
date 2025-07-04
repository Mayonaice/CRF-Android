#!/bin/bash

echo "Generating app icons for DCT CRF Android..."

# Check if app_icon.png exists
if [ ! -f "assets/images/app_icon.png" ]; then
    echo "Error: assets/images/app_icon.png not found!"
    exit 1
fi

# Create directories if they don't exist
mkdir -p android/app/src/main/res/mipmap-hdpi
mkdir -p android/app/src/main/res/mipmap-mdpi
mkdir -p android/app/src/main/res/mipmap-xhdpi
mkdir -p android/app/src/main/res/mipmap-xxhdpi
mkdir -p android/app/src/main/res/mipmap-xxxhdpi

# Remove any existing XML icon files
rm -f android/app/src/main/res/mipmap-*/ic_launcher.xml

echo "Converting app_icon.png to different sizes..."

# Use ImageMagick to convert to different sizes
if command -v convert &> /dev/null; then
    echo "Using ImageMagick convert..."
    convert assets/images/app_icon.png -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    convert assets/images/app_icon.png -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    convert assets/images/app_icon.png -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    convert assets/images/app_icon.png -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    convert assets/images/app_icon.png -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    echo "Icons generated successfully using ImageMagick!"
else
    echo "ImageMagick not found, copying original PNG to all directories..."
    # Fallback: copy original PNG to all directories
    cp assets/images/app_icon.png android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    cp assets/images/app_icon.png android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    cp assets/images/app_icon.png android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    cp assets/images/app_icon.png android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    cp assets/images/app_icon.png android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    echo "Icons copied successfully!"
fi

# Verify icons were created
echo "Verifying generated icons:"
find android/app/src/main/res/mipmap-* -name "ic_launcher.png" -exec ls -la {} \;

echo "Icon generation complete!"
echo "You can now build your app with: flutter build apk" 
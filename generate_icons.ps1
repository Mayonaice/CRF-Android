Write-Host "Generating app icons for DCT CRF Android..." -ForegroundColor Green

# Check if app_icon.png exists
if (-not (Test-Path "assets/images/app_icon.png")) {
    Write-Host "Error: assets/images/app_icon.png not found!" -ForegroundColor Red
    exit 1
}

# Create directories if they don't exist
$directories = @(
    "android/app/src/main/res/mipmap-hdpi",
    "android/app/src/main/res/mipmap-mdpi", 
    "android/app/src/main/res/mipmap-xhdpi",
    "android/app/src/main/res/mipmap-xxhdpi",
    "android/app/src/main/res/mipmap-xxxhdpi"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir"
    }
}

# Remove any existing XML icon files
Get-ChildItem -Path "android/app/src/main/res/mipmap-*" -Filter "ic_launcher.xml" -ErrorAction SilentlyContinue | Remove-Item -Force

Write-Host "Converting app_icon.png to different sizes..."

# Check if ImageMagick is available
$magickPath = Get-Command "magick" -ErrorAction SilentlyContinue
if ($magickPath) {
    Write-Host "Using ImageMagick convert..." -ForegroundColor Yellow
    
    # Convert to different sizes using ImageMagick
    magick assets/images/app_icon.png -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
    magick assets/images/app_icon.png -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
    magick assets/images/app_icon.png -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
    magick assets/images/app_icon.png -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
    magick assets/images/app_icon.png -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
    
    Write-Host "Icons generated successfully using ImageMagick!" -ForegroundColor Green
} else {
    Write-Host "ImageMagick not found, copying original PNG to all directories..." -ForegroundColor Yellow
    
    # Fallback: copy original PNG to all directories
    Copy-Item "assets/images/app_icon.png" "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" -Force
    Copy-Item "assets/images/app_icon.png" "android/app/src/main/res/mipmap-mdpi/ic_launcher.png" -Force
    Copy-Item "assets/images/app_icon.png" "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png" -Force
    Copy-Item "assets/images/app_icon.png" "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png" -Force
    Copy-Item "assets/images/app_icon.png" "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" -Force
    
    Write-Host "Icons copied successfully!" -ForegroundColor Green
}

# Verify icons were created
Write-Host "Verifying generated icons:" -ForegroundColor Cyan
Get-ChildItem -Path "android/app/src/main/res/mipmap-*" -Filter "ic_launcher.png" -Recurse | ForEach-Object {
    Write-Host "  $($_.FullName) - $($_.Length) bytes"
}

Write-Host "Icon generation complete!" -ForegroundColor Green
Write-Host "You can now build your app with: flutter build apk" -ForegroundColor Yellow 
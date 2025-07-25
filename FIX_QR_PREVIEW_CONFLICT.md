# Panduan Memperbaiki Konflik 'Preview' Class di QR Mobile Vision

## Masalah

Error ini terjadi karena ada konflik antara dua kelas dengan nama yang sama:

```
../../../AppData/Local/Pub/Cache/hosted/pub.dev/qr_mobile_vision-4.1.4/lib/src/qr_camera.dart:161:24: Error: 'Preview'
is imported from both 'package:flutter/src/widgets/widget_preview.dart' and 'package:qr_mobile_vision/src/preview.dart'.
                child: Preview(
```

Kelas `Preview` ada di dua tempat:
1. Flutter SDK: `package:flutter/src/widgets/widget_preview.dart`
2. Package QR Mobile Vision: `package:qr_mobile_vision/src/preview.dart`

## Solusi

### Langkah 1: Edit file QR Mobile Vision

1. Buka file di lokasi:
```
C:\Users\WS24001748\AppData\Local\Pub\Cache\hosted\pub.dev\qr_mobile_vision-4.1.4\lib\src\qr_camera.dart
```

2. Ubah semua `Preview` menjadi `QRPreview` di file tersebut

### Langkah 2: Edit file Preview Definition

1. Buka file:
```
C:\Users\WS24001748\AppData\Local\Pub\Cache\hosted\pub.dev\qr_mobile_vision-4.1.4\lib\src\preview.dart
```

2. Ubah definisi kelas dari `class Preview` menjadi `class QRPreview`

### Cara Cepat dengan PowerShell

Jalankan perintah berikut di PowerShell:

```powershell
# Ubah Preview menjadi QRPreview di qr_camera.dart
(Get-Content "C:\Users\WS24001748\AppData\Local\Pub\Cache\hosted\pub.dev\qr_mobile_vision-4.1.4\lib\src\qr_camera.dart") | 
    ForEach-Object {$_ -replace "Preview\(", "QRPreview("} |
    ForEach-Object {$_ -replace "class Preview", "class QRPreview"} |
    Set-Content "C:\Users\WS24001748\AppData\Local\Pub\Cache\hosted\pub.dev\qr_mobile_vision-4.1.4\lib\src\qr_camera.dart"

# Ubah class di preview.dart jika file ada
if (Test-Path "C:\Users\WS24001748\AppData\Local\Pub\Cache\hosted\pub.dev\qr_mobile_vision-4.1.4\lib\src\preview.dart") {
    (Get-Content "C:\Users\WS24001748\AppData\Local\Pub\Cache\hosted\pub.dev\qr_mobile_vision-4.1.4\lib\src\preview.dart") | 
    ForEach-Object {$_ -replace "class Preview", "class QRPreview"} |
    Set-Content "C:\Users\WS24001748\AppData\Local\Pub\Cache\hosted\pub.dev\qr_mobile_vision-4.1.4\lib\src\preview.dart"
}
```

## Alternatif: Gunakan Script Bash

Jika Anda menggunakan Git Bash atau WSL:

```bash
# Ubah Preview menjadi QRPreview di qr_camera.dart
sed -i 's/Preview(/QRPreview(/g' "$HOME/AppData/Local/Pub/Cache/hosted/pub.dev/qr_mobile_vision-4.1.4/lib/src/qr_camera.dart"
sed -i 's/class Preview/class QRPreview/g' "$HOME/AppData/Local/Pub/Cache/hosted/pub.dev/qr_mobile_vision-4.1.4/lib/src/qr_camera.dart"

# Ubah class di preview.dart jika file ada
if [ -f "$HOME/AppData/Local/Pub/Cache/hosted/pub.dev/qr_mobile_vision-4.1.4/lib/src/preview.dart" ]; then
    sed -i 's/class Preview/class QRPreview/g' "$HOME/AppData/Local/Pub/Cache/hosted/pub.dev/qr_mobile_vision-4.1.4/lib/src/preview.dart"
fi
```

## Alternatif: Edit Manual

Jika skrip tidak berfungsi, Anda dapat mengedit file secara manual:

1. Buka file di Visual Studio Code atau editor teks lain
2. Cari semua kejadian "Preview" dan ganti dengan "QRPreview"
3. Simpan file

## Verifikasi

Setelah perubahan, coba jalankan aplikasi lagi dengan:

```bash
flutter run
```

Error seharusnya sudah tidak muncul lagi.

## Catatan Penting

Saat melakukan update package dengan `flutter pub get`, modifikasi ini mungkin hilang. Jika terjadi error lagi, ulangi langkah-langkah di atas.

## Solusi Permanen

Untuk solusi jangka panjang, pertimbangkan untuk menggunakan package QR scanner alternatif seperti:
- mobile_scanner: ^3.5.7
- flutter_barcode_scanner: ^2.0.0 
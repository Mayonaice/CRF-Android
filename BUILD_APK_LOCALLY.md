# CARA BUILD APK DI KOMPUTER LOKAL TANPA CODEMAGIC

Jika Anda mengalami kesulitan dengan Codemagic, Anda dapat membuild APK secara lokal di komputer Anda. Ikuti langkah-langkah berikut.

## Persiapan

1. **Pastikan Flutter SDK terinstal**
   - Jika belum, install dari [flutter.dev](https://flutter.dev/docs/get-started/install)
   - Tambahkan Flutter ke PATH

2. **Pastikan Android SDK terinstal**
   - Install Android Studio atau hanya SDK Tools

3. **Pastikan Java terinstal (JDK 17)**
   - `java -version` untuk memeriksa

## Langkah Build APK

1. **Buka terminal/command prompt**

2. **Arahkan ke direktori proyek**
   ```
   cd path/ke/crf-and1
   ```

3. **Update dependensi**
   ```
   flutter clean
   flutter pub get
   ```

4. **Perbaiki masalah icons**
   - Buka file `lib/widgets/qr_code_scanner_tl_widget.dart`
   - Ubah `Icons.camera_off` menjadi `Icons.no_photography`
   - Atau jalankan:
     ```
     powershell -Command "(Get-Content lib/widgets/qr_code_scanner_tl_widget.dart) -replace 'Icons.camera_off', 'Icons.no_photography' | Set-Content lib/widgets/qr_code_scanner_tl_widget.dart"
     ```

5. **Build APK**
   ```
   flutter build apk --debug --no-shrink
   ```

6. **Lokasi file APK**
   - Cek di folder `build/app/outputs/flutter-apk/app-debug.apk`

7. **Rename untuk distribusi (opsional)**
   ```
   copy build/app/outputs/flutter-apk/app-debug.apk CRF_Android_final.apk
   ```

## Troubleshooting

1. **Jika gagal build karena error Preview conflict**:
   - Ubah custom widget QrCamera menjadi tampilan alternatif

2. **Jika ada error gradle**:
   - Perbaiki gradle wrapper:
     ```
     cd android
     ./gradlew wrapper
     ```

3. **Jika ada warning CocoaPods**:
   - Abaikan saja, itu hanya untuk iOS

## Distribusi APK

1. **Transfer ke HP melalui WhatsApp/Telegram/Email**

2. **Upload ke Firebase App Distribution**
   - Setup dengan [panduan Firebase](https://firebase.google.com/docs/app-distribution/android/distribute-console)

3. **Buat Shared Drive/Folder**
   - Upload APK dan bagikan linknya

## Menginstal di Perangkat Android

1. **Pastikan sumber tidak dikenal diaktifkan**
   - Settings > Security > Unknown sources

2. **Buka file APK yang ditransfer**
   - Klik untuk install

3. **Jika ada warning**
   - Pilih "Install anyway" atau "Install dari sumber ini"

## Dukungan Perangkat

- Android 5.0 (Lollipop) atau lebih baru
- Min 2GB RAM
- Kamera belakang yang berfungsi 
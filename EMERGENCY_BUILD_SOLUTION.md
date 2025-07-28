# SOLUSI DARURAT: BUILD APK SECARA LOKAL

Karena build di Codemagic terus mengalami masalah dengan error Gradle yang tidak spesifik, berikut adalah solusi darurat untuk membuild APK secara lokal dan mendapatkan file APK yang dapat digunakan.

## Langkah 1: Persiapan Lingkungan

1. **Pastikan Android SDK terinstal**:
   - Jika belum terinstal, download dan instal Android Studio dari [sini](https://developer.android.com/studio)
   - Buka Android Studio → SDK Manager → Instal Android SDK

2. **Pastikan Flutter terinstal**:
   - Jika belum terinstal, ikuti panduan di [flutter.dev](https://flutter.dev/docs/get-started/install)

3. **Pastikan variabel lingkungan diatur dengan benar**:
   - Buka PowerShell sebagai Administrator
   - Jalankan:
     ```powershell
     [Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Users\WS24001748\AppData\Local\Android\sdk", "User")
     [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "C:\Users\WS24001748\AppData\Local\Android\sdk", "User")
     ```
   - Restart PowerShell atau Command Prompt

## Langkah 2: Persiapkan Project

1. **Buat file `local.properties` di folder `android`**:
   ```properties
   sdk.dir=C:\\Users\\WS24001748\\AppData\\Local\\Android\\sdk
   flutter.sdk=C:\\flutter
   ```

2. **Bersihkan project**:
   ```bash
   cd crf-and1
   flutter clean
   flutter pub get
   ```

## Langkah 3: Build APK dengan Opsi Minimal

1. **Build APK debug tanpa optimasi**:
   ```bash
   flutter build apk --debug --no-shrink
   ```

2. **Jika masih error, coba build dengan flag tambahan**:
   ```bash
   flutter build apk --debug --no-shrink --no-tree-shake-icons
   ```

## Langkah 4: Gunakan Gradle Secara Langsung

Jika Flutter build masih gagal, coba build langsung dengan Gradle:

1. **Buka terminal di folder `android`**:
   ```bash
   cd android
   ```

2. **Build dengan Gradle**:
   ```bash
   # Di Windows
   .\gradlew.bat assembleDebug --stacktrace --info

   # Di Linux/Mac
   ./gradlew assembleDebug --stacktrace --info
   ```

## Langkah 5: Gunakan Android Studio

Jika semua cara di atas gagal, gunakan Android Studio:

1. **Buka project di Android Studio**
2. **Klik Build → Build Bundle(s) / APK(s) → Build APK(s)**
3. **Tunggu hingga build selesai**
4. **Klik "locate" pada notifikasi build selesai**

## Lokasi APK

APK yang berhasil dibuild akan berada di salah satu lokasi berikut:

- `build/app/outputs/flutter-apk/app-debug.apk` (jika menggunakan Flutter build)
- `android/app/build/outputs/apk/debug/app-debug.apk` (jika menggunakan Gradle atau Android Studio)

## Solusi Alternatif: Gunakan APK dari Build Sebelumnya

Jika semua cara di atas gagal, gunakan APK dari build sebelumnya yang berhasil (jika ada).

## Solusi Terakhir: Sederhanakan Project

Jika semua cara di atas gagal, pertimbangkan untuk menyederhanakan project:

1. **Buat project Flutter baru**
2. **Salin kode sumber dari project lama ke project baru**
3. **Tambahkan dependensi secara bertahap, build setelah setiap penambahan**
4. **Identifikasi dependensi yang menyebabkan masalah**

## Catatan Penting

1. **Error Gradle yang Tidak Spesifik**:
   - Error `DefaultWorkerLeaseService` dan `DefaultConditionalExecutionQueue` biasanya menunjukkan masalah dengan konfigurasi Gradle atau konflik dependensi
   - Sulit didiagnosis tanpa log lengkap

2. **Perbedaan Lingkungan**:
   - Build di Codemagic dan build lokal mungkin berbeda karena perbedaan lingkungan
   - Codemagic menggunakan macOS, sementara build lokal mungkin menggunakan Windows/Linux

3. **Distribusi APK**:
   - APK debug dapat digunakan untuk testing
   - Untuk distribusi ke pengguna, sebaiknya gunakan APK release yang ditandatangani 
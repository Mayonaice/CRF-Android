# SOLUSI TERAKHIR: BUILD APK SECARA LOKAL

Karena build di Codemagic terus mengalami masalah yang sulit diatasi, berikut adalah solusi terakhir untuk mendapatkan APK yang berfungsi dengan build secara lokal.

## Langkah 1: Persiapan Lingkungan Windows

1. **Instal Android Studio**:
   - Download dari [developer.android.com/studio](https://developer.android.com/studio)
   - Instal dengan semua komponen default

2. **Pastikan Android SDK terinstal**:
   - Buka Android Studio → Settings → Appearance & Behavior → System Settings → Android SDK
   - Pastikan Android SDK Platform 34 terinstal
   - Pastikan Android SDK Build-Tools 34.0.0 terinstal
   - Catat lokasi Android SDK (biasanya di `C:\Users\[username]\AppData\Local\Android\Sdk`)

3. **Instal Flutter**:
   - Download dari [flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)
   - Ekstrak ke lokasi yang diinginkan (misalnya `C:\flutter`)
   - Tambahkan Flutter ke PATH:
     ```
     setx PATH "%PATH%;C:\flutter\bin"
     ```

4. **Atur variabel lingkungan**:
   - Buka PowerShell sebagai Administrator
   - Jalankan:
     ```powershell
     [Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Users\WS24001748\AppData\Local\Android\Sdk", "User")
     [Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "C:\Users\WS24001748\AppData\Local\Android\Sdk", "User")
     ```
   - Restart PowerShell

## Langkah 2: Build APK dengan Android Studio

1. **Buka project di Android Studio**:
   - Buka Android Studio
   - Pilih "Open an existing project"
   - Navigasi ke folder `crf-and1` dan buka

2. **Sync Gradle**:
   - Tunggu Android Studio menyelesaikan indexing
   - Klik "Sync Project with Gradle Files" (ikon Gradle di toolbar)

3. **Build APK**:
   - Pilih Build → Build Bundle(s) / APK(s) → Build APK(s)
   - Tunggu proses build selesai
   - Klik "locate" pada notifikasi untuk menemukan APK

4. **Lokasi APK**:
   - APK akan berada di `android/app/build/outputs/apk/debug/app-debug.apk`

## Langkah 3: Alternatif Build APK dengan Command Line

Jika Android Studio tidak berfungsi dengan baik, gunakan command line:

1. **Persiapkan project**:
   ```bash
   cd crf-and1
   flutter clean
   flutter pub get
   ```

2. **Build APK**:
   ```bash
   flutter build apk --debug --no-shrink
   ```

3. **Lokasi APK**:
   - APK akan berada di `build/app/outputs/flutter-apk/app-debug.apk`

## Langkah 4: Jika Semua Cara Gagal - Gunakan Flutter 3.10.0

Jika semua cara di atas gagal, coba downgrade Flutter ke versi yang lebih stabil:

1. **Instal Flutter 3.10.0**:
   - Download dari [flutter.dev/docs/development/tools/sdk/releases](https://flutter.dev/docs/development/tools/sdk/releases)
   - Atau gunakan Flutter version management:
     ```bash
     flutter version 3.10.0
     ```

2. **Perbarui dependencies**:
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Build APK**:
   ```bash
   flutter build apk --debug --no-shrink
   ```

## Langkah 5: Distribusi APK

Setelah mendapatkan APK, Anda dapat mendistribusikannya dengan cara:

1. **Email**: Kirim APK langsung via email
2. **Google Drive/Dropbox**: Upload dan bagikan link
3. **Firebase App Distribution**: Untuk distribusi yang lebih terorganisir

## Catatan Penting

1. **APK Debug vs Release**:
   - APK debug memiliki performa lebih lambat dan ukuran lebih besar
   - Untuk produksi, sebaiknya gunakan APK release (`flutter build apk --release`)

2. **Masalah Codemagic**:
   - Codemagic mungkin memiliki konfigurasi atau versi yang berbeda dari lingkungan lokal
   - Perbedaan OS (macOS di Codemagic vs Windows lokal) dapat menyebabkan masalah

3. **Jangan Buang Waktu Lagi dengan Codemagic**:
   - Jika sudah mencoba berbagai solusi dan masih gagal, lebih baik fokus pada build lokal
   - Setelah aplikasi stabil, baru coba konfigurasi CI/CD lagi 
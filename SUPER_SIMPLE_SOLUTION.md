# CARA MEMBUILD APK SECARA MANUAL (SOLUSI TERAKHIR)

Jika build Codemagic tetap tidak berhasil, ikuti langkah-langkah berikut untuk membuild APK secara manual dan mendapatkan file APK.

## Cara 1: Build Secara Lokal dengan Flutter

1. **Persiapkan lingkungan**:
   ```bash
   cd crf-and1
   flutter clean
   flutter pub get
   ```

2. **Perbaiki icon error**:
   ```bash
   sed -i 's/Icons.camera_off/Icons.no_photography/g' lib/widgets/qr_code_scanner_tl_widget.dart
   ```

3. **Build APK**:
   ```bash
   flutter build apk --debug --no-shrink
   ```

4. **Lokasi APK**:
   - APK akan tersedia di `build/app/outputs/flutter-apk/app-debug.apk`
   - Anda dapat menggunakan APK ini langsung di perangkat Android

## Cara 2: Build dengan Android Studio

1. **Buka project di Android Studio**
2. **Klik Build → Build Bundle(s) / APK(s) → Build APK(s)**
3. **Tunggu hingga build selesai**
4. **Klik "locate" pada notifikasi build selesai**

## Cara 3: Upload ke Firebase App Distribution

Jika Anda kesulitan dengan Codemagic:

1. **Siapkan Firebase Project**:
   - Buat project di Firebase Console
   - Tambahkan aplikasi Android (com.advantage.crf)

2. **Gunakan App Distribution**:
   - Upload APK yang dibuild secara lokal
   - Distribusikan ke tester via email

## Cara 4: Upload Manual ke Device

1. **Hubungkan perangkat Android via USB**
2. **Aktifkan mode developer dan USB debugging**
3. **Copy file APK ke perangkat**:
   ```bash
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

## Menyederhanakan File codemagic.yaml

Jika masih ingin mencoba Codemagic, gunakan konfigurasi sangat sederhana berikut:

```yaml
workflows:
  android-debug:
    name: Android Debug Build
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      flutter: 3.16.9
      java: 17
    scripts:
      - name: Build APK
        script: |
          flutter clean
          flutter pub get
          flutter build apk --debug
    artifacts:
      - build/app/outputs/flutter-apk/*.apk
```

File ini sangat minimal tetapi seharusnya cukup untuk menghasilkan APK. 
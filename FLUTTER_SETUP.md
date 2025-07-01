# Instalasi Flutter dan Menjalankan Aplikasi CRF

Berikut adalah langkah-langkah untuk menginstall Flutter dan menjalankan aplikasi CRF dengan perintah `flutter run -d edge`:

## Langkah 1: Menginstall Flutter SDK

1. **Download Flutter SDK**:
   - Kunjungi [flutter.dev/docs/get-started/install/windows](https://flutter.dev/docs/get-started/install/windows)
   - Download Flutter SDK terbaru (zip file)
   - Extract file zip ke lokasi yang diinginkan (misalnya: `C:\flutter`)

2. **Tambahkan Flutter ke PATH**:
   - Buka Start Menu, ketik "environment variables" dan pilih "Edit the system environment variables"
   - Klik "Environment Variables"
   - Di bagian "System variables", cari variabel "Path", pilih dan klik "Edit"
   - Klik "New" dan tambahkan path tempat Flutter diextract, diikuti dengan '\bin' (misalnya: `C:\flutter\bin`)
   - Klik "OK" di semua dialog

3. **Verifikasi Instalasi**:
   - Buka Command Prompt baru atau PowerShell
   - Jalankan perintah: `flutter --version`
   - Jika terinstall dengan benar, akan muncul informasi versi Flutter

## Langkah 2: Aktifkan Flutter Web Support

1. **Jalankan perintah berikut**:
   ```
   flutter config --enable-web
   ```

2. **Verifikasi Web Support**:
   ```
   flutter devices
   ```
   Pastikan Chrome dan Edge muncul di daftar devices.

## Langkah 3: Menjalankan Aplikasi CRF

1. **Masuk ke direktori aplikasi**:
   ```
   cd crf-and1
   ```

2. **Jalankan aplikasi di Edge**:
   ```
   flutter run -d edge
   ```

3. **Atau, gunakan spesifikasi device yang lebih jelas**:
   ```
   flutter devices
   ```
   Identifikasi ID untuk Microsoft Edge, lalu jalankan:
   ```
   flutter run -d <edge-device-id>
   ```

## Troubleshooting

Jika mengalami masalah, coba langkah-langkah berikut:

1. **Pastikan Flutter SDK terinstall dengan benar**:
   ```
   flutter doctor
   ```
   Ikuti petunjuk untuk memperbaiki masalah yang ditemukan.

2. **Pastikan Edge terinstall**:
   Aplikasi memerlukan Microsoft Edge (Chromium-based) versi terbaru.

3. **Jika Edge tidak terdeteksi**:
   - Pastikan Edge sudah terbuka
   - Coba restart komputer
   - Coba jalankan di Chrome sebagai alternatif:
     ```
     flutter run -d chrome
     ```

4. **Masalah dengan pubspec.yaml**:
   Jika ada pesan error tentang pubspec.yaml, jalankan:
   ```
   flutter pub get
   ```

5. **Aktifkan mode developer di browser**:
   Jika aplikasi tidak berjalan, pastikan mode developer di browser sudah aktif.

## Catatan Penting

- Aplikasi dirancang untuk tampilan landscape, pastikan tidak memutar layar ke mode portrait.
- Untuk pengalaman terbaik, gunakan mode full screen (F11) di browser.
- Pastikan komputer terkoneksi ke jaringan yang dapat mengakses server API (10.10.0.223).
- Jika ada pertanyaan atau masalah, silakan hubungi tim pengembang. 
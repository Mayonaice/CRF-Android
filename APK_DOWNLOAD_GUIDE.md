# Panduan Mengunduh APK dari Codemagic

## Langkah-Langkah Mengunduh APK dari Codemagic

1. **Login ke Codemagic**
   - Buka [https://codemagic.io/apps](https://codemagic.io/apps)
   - Masuk dengan akun yang memiliki akses ke proyek CRF Android

2. **Pilih Aplikasi**
   - Pilih aplikasi "crf-and1" dari daftar aplikasi Anda

3. **Pilih Build Terbaru**
   - Cari build terbaru yang "Successful" (ditandai dengan warna hijau)
   - Klik pada build tersebut untuk melihat detailnya

4. **Unduh APK**
   - Scroll ke bawah sampai bagian "Artifacts"
   - Cari file `CRF_Android_final.apk`
   - Klik tombol "Download" di sebelah file tersebut
   - File APK akan mulai diunduh

## Jika APK Tidak Tersedia

Jika Anda tidak melihat file APK di bagian Artifacts, coba periksa hal berikut:

1. **Periksa Status Build**
   - Pastikan build status-nya "Successful" (hijau)
   - Jika gagal (merah), baca pesan error untuk mengetahui penyebabnya

2. **Cek Log Build**
   - Buka tab "Logs" pada detail build
   - Cari pesan error terkait build APK
   - Perhatikan bagian "Build APK with Flutter" dan "Prepare APK artifacts"

3. **Path File APK yang Mungkin**
   - `build/app/outputs/flutter-apk/app-debug.apk`
   - `android/app/build/outputs/apk/debug/app-debug.apk`
   - `android/app/build/outputs/apk/debug/CRF_Android_final.apk`
   - `$FCI_BUILD_OUTPUT_DIR/CRF_Android_final.apk`

4. **Jalankan Build Ulang**
   - Jika masih belum tersedia, coba jalankan build ulang dengan klik tombol "Rebuild"

## Install APK di Perangkat Android

Setelah mengunduh file APK:

1. Transfer file APK ke perangkat Android Anda (via email, WhatsApp, atau kabel USB)

2. Pada perangkat Android, buka File Manager dan navigasikan ke lokasi file APK

3. Ketuk file APK untuk menginstalnya
   - Anda mungkin perlu mengaktifkan opsi "Install from Unknown Sources" di pengaturan keamanan perangkat

4. Ikuti petunjuk instalasi di layar

5. Setelah instalasi selesai, buka aplikasi CRF

## Perangkat yang Didukung

- Android 5.0 (Lollipop) atau lebih baru
- Minimal RAM 2GB
- Kamera belakang yang berfungsi dengan baik (untuk scan QR) 
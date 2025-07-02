# Cara Menjalankan Aplikasi CRF dengan Flutter

## Cara Cepat (Jika Flutter Sudah Terinstall)

1. Buka terminal/command prompt
2. Masuk ke direktori aplikasi:
   ```
   cd path/to/crf-and1
   ```
3. Pastikan semua dependencies terinstall:
   ```
   flutter pub get
   ```
4. Jalankan aplikasi di Edge:
   ```
   flutter run -d edge
   ```

## Detail Lengkap

Jika Anda perlu menginstall Flutter atau menemui masalah, lihat file `FLUTTER_SETUP.md` untuk instruksi lengkap.

## Catatan Penting

- Pastikan file gambar berikut sudah ada di folder `assets/images/`:
  - logo.png, crf_logo.png, user.jpg - Gambar dasar aplikasi
  - A50.png - Gambar uang Rp 50.000 (untuk tipeDenom A50)
  - A100.png - Gambar uang Rp 100.000 (untuk tipeDenom A100)
- Pastikan file font (Arial.ttf) sudah ada di folder `assets/fonts/`
- Aplikasi memerlukan koneksi ke server API di 10.10.0.223

## Fitur Baru: Tampilan Uang di Prepare Mode

- Prepare Mode sekarang menampilkan gambar uang sesuai dengan tipeDenom dari API
- Jika tipeDenom = A50, akan menampilkan gambar uang Rp 50.000
- Jika tipeDenom = A100, akan menampilkan gambar uang Rp 100.000
- Total nominal dihitung dari tipeDenom × standValue 
# Implementasi QR Scanner Alternatif

## Latar Belakang

Aplikasi CRF_TL mengalami masalah dengan scanner QR code yang menggunakan package `qr_mobile_vision`. Masalah utama yang terjadi adalah:

1. **Infinite Loading**: Scanner sering kali terjebak dalam status loading tanpa pernah menampilkan preview kamera
2. **Timeout**: Tidak ada mekanisme timeout yang baik ketika kamera gagal diinisialisasi
3. **Konflik Class**: Terjadi konflik antara class `Preview` dari Flutter dan dari package `qr_mobile_vision`
4. **Tidak Stabil**: Pada beberapa perangkat, scanner tidak berfungsi dengan baik

## Solusi: QR Scanner Alternatif

Untuk mengatasi masalah tersebut, telah diimplementasikan scanner QR code alternatif menggunakan package `qr_code_scanner` yang lebih stabil dan reliable. Package ini menggunakan:

- **Android**: ZXing library (library standar untuk barcode scanning di Android)
- **iOS**: MTBBarcodeScanner (library yang stabil untuk iOS)

## Fitur QR Scanner Alternatif

1. **Stabilitas Lebih Baik**: Menggunakan library native yang lebih stabil dan teruji
2. **Toggle Flash**: Kemampuan untuk menyalakan/mematikan flash
3. **Flip Camera**: Kemampuan untuk berganti antara kamera depan dan belakang
4. **Overlay Scanner**: Tampilan overlay yang membantu pengguna mengarahkan kamera
5. **Support Multi-format**: Mendukung berbagai format barcode (QR, Aztec, DataMatrix, dll)
6. **Haptic Feedback**: Memberikan feedback getaran saat QR code terdeteksi
7. **Manual Input**: Tetap menyediakan opsi input manual

## Cara Menggunakan

Aplikasi sekarang menyediakan opsi untuk memilih antara scanner default (qr_mobile_vision) atau scanner alternatif (qr_code_scanner):

1. Tap tombol "Scan QR Code" di layar utama
2. Pada dialog yang muncul, aktifkan switch "Scanner alternatif" untuk menggunakan scanner alternatif
3. Pilih "Scanner Kamera" untuk memulai scanning

## Implementasi Teknis

Implementasi scanner alternatif terdiri dari beberapa komponen:

### 1. QRScannerAlternative Widget (`lib/widgets/qr_scanner_alternative.dart`)

Widget ini mengimplementasikan scanner QR code menggunakan package `qr_code_scanner`. Widget ini menyediakan:

- Preview kamera fullscreen
- Overlay scanner dengan border hijau
- Tombol untuk toggle flash dan flip camera
- Handler untuk mendeteksi dan memproses QR code

### 2. Integrasi dengan TLQRScannerScreen (`lib/screens/tl_qr_scanner_screen.dart`)

Screen utama untuk scanning QR code telah dimodifikasi untuk:

- Menyediakan opsi untuk memilih antara scanner default atau alternatif
- Menangani hasil scanning dari kedua jenis scanner
- Menyediakan timeout dan error handling yang lebih baik

### 3. Dependencies di pubspec.yaml

Penambahan package `qr_code_scanner` di `pubspec.yaml`:

```yaml
dependencies:
  # ... dependencies lainnya
  qr_mobile_vision: ^6.0.0 # Current QR scanner package
  qr_code_scanner: ^1.0.1 # Alternative QR scanner package with better reliability
```

## Perbandingan dengan Scanner Default

| Fitur | Scanner Default (qr_mobile_vision) | Scanner Alternatif (qr_code_scanner) |
|-------|-----------------------------------|--------------------------------------|
| Stabilitas | Kurang stabil, sering infinite loading | Lebih stabil |
| Kecepatan Deteksi | Cepat (jika berhasil load) | Cepat dan konsisten |
| Toggle Flash | Ya | Ya |
| Flip Camera | Tidak | Ya |
| Overlay Scanner | Tidak | Ya |
| Manual Input | Ya | Ya |
| Timeout Handling | Manual (implementasi custom) | Built-in |
| Lifecycle Management | Manual (implementasi custom) | Built-in |

## Troubleshooting

Jika scanner alternatif mengalami masalah:

1. **Tidak Dapat Mengakses Kamera**: Pastikan aplikasi memiliki izin untuk mengakses kamera di pengaturan perangkat
2. **Preview Hitam**: Coba restart aplikasi atau gunakan tombol "Flip Camera" untuk mengganti kamera
3. **Tidak Dapat Mendeteksi QR Code**: Pastikan QR code dalam kondisi baik (tidak rusak/blur) dan cukup cahaya
4. **Aplikasi Crash**: Kembali ke scanner default dengan mematikan switch "Scanner alternatif"

## Rekomendasi

Berdasarkan pengujian, scanner alternatif menggunakan `qr_code_scanner` lebih direkomendasikan karena:

1. Lebih stabil dan reliable
2. Memiliki fitur yang lebih lengkap
3. Lebih responsif terhadap lifecycle aplikasi
4. Memiliki tampilan yang lebih user-friendly dengan overlay scanner

Namun, scanner default tetap disediakan sebagai fallback jika scanner alternatif tidak berfungsi pada perangkat tertentu. 
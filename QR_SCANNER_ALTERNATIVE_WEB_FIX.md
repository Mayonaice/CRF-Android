# Perbaikan Error platformViewRegistry di Web Platform

## Masalah yang Terjadi

Saat mencoba menggunakan package `qr_code_scanner` di web platform, terjadi error:

```
../../../AppData/Local/Pub/Cache/hosted/pub.dev/qr_code_scanner-1.0.1/lib/src/web/flutter_qr_web.dart:84:8: Error:
Undefined name 'platformViewRegistry'.
    ui.platformViewRegistry
       ^^^^^^^^^^^^^^^^^^^^
```

Error ini terjadi karena package `qr_code_scanner` memiliki implementasi web yang tidak kompatibel dengan versi Flutter terbaru. Pada versi Flutter terbaru, `platformViewRegistry` telah diubah cara aksesnya.

## Solusi yang Diterapkan

Untuk mengatasi masalah ini, kami mengimplementasikan beberapa solusi:

### 1. Conditional Import dengan Stub File

Kami membuat file stub (`qr_scanner_stub.dart`) yang akan digunakan sebagai pengganti package `qr_code_scanner` saat aplikasi berjalan di platform web:

```dart
// Import qr_code_scanner hanya jika bukan web platform
import 'package:qr_code_scanner/qr_code_scanner.dart' if (dart.library.js) 'qr_scanner_stub.dart';
```

### 2. Implementasi Stub File

File `qr_scanner_stub.dart` berisi implementasi dummy dari class-class yang diperlukan:

```dart
// File stub untuk qr_code_scanner di web platform
// Berisi class dan enum yang diperlukan untuk menghindari error kompilasi

import 'package:flutter/material.dart';

// Stub untuk BarcodeFormat
enum BarcodeFormat {
  qrcode,
  aztec,
  dataMatrix,
  pdf417,
  code39,
  code93,
  code128,
  ean8,
  ean13,
}

// Stub untuk QRView
class QRView extends StatelessWidget {
  // ... implementasi dummy ...
}

// Stub untuk QRViewController
class QRViewController {
  // ... implementasi dummy ...
}

// Stub untuk QrScannerOverlayShape
class QrScannerOverlayShape {
  // ... implementasi dummy ...
}

// Stub untuk Barcode
class Barcode {
  // ... implementasi dummy ...
}
```

### 3. Penanganan Platform Web di QRScannerAlternative

Di widget `QRScannerAlternative`, kami menambahkan pengecekan platform dan menampilkan UI alternatif jika aplikasi berjalan di web:

```dart
@override
Widget build(BuildContext context) {
  // Jika platform web, tampilkan pesan error karena qr_code_scanner tidak didukung di web
  if (kIsWeb) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'Scanner alternatif tidak didukung di web',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // ... UI lainnya ...
          ],
        ),
      ),
    );
  }
  
  // Implementasi normal untuk platform mobile
  return Scaffold(
    // ... implementasi scanner untuk mobile ...
  );
}
```

### 4. Penanganan Platform Web di TLQRScannerScreen

Di screen `TLQRScannerScreen`, kami memodifikasi dialog pemilihan scanner untuk:

1. Menyembunyikan opsi scanner alternatif di web platform
2. Menampilkan pesan error jika user mencoba menggunakan scanner alternatif di web
3. Mengarahkan user untuk menggunakan input manual di web

```dart
// Tampilkan switch hanya jika bukan di web platform
if (!kIsWeb)
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Scanner alternatif: '),
      Switch(
        value: _useAlternativeScanner,
        activeColor: Colors.green,
        onChanged: (value) {
          setState(() {
            _useAlternativeScanner = value;
            Navigator.of(context).pop();
            _startQRScan();
          });
        },
      ),
    ],
  ),
```

## Hasil Perbaikan

Dengan implementasi ini, aplikasi sekarang dapat dikompilasi dan berjalan di platform web tanpa error `platformViewRegistry`. Perilaku aplikasi di masing-masing platform:

1. **Platform Mobile (Android/iOS)**:
   - Dapat menggunakan scanner default (qr_mobile_vision)
   - Dapat menggunakan scanner alternatif (qr_code_scanner)
   - Dapat menggunakan input manual

2. **Platform Web**:
   - Tidak menampilkan opsi scanner alternatif
   - Menampilkan pesan error jika mencoba menggunakan scanner alternatif
   - Dapat menggunakan scanner default (qr_mobile_vision)
   - Dapat menggunakan input manual

## Catatan Penting

1. Package `qr_code_scanner` tidak mendukung web platform dengan baik. Jika membutuhkan scanner QR code yang berfungsi di web, pertimbangkan untuk menggunakan package lain seperti `mobile_scanner` yang memiliki dukungan web yang lebih baik.

2. Pendekatan stub file ini adalah solusi sementara untuk mengatasi error kompilasi. Untuk solusi jangka panjang, sebaiknya menggunakan package yang memiliki dukungan web yang lebih baik atau implementasi custom untuk web platform. 
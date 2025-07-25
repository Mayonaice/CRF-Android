# Perbaikan Error GlobalKey pada QR Scanner

## Error yang Terjadi

Aplikasi mengalami beberapa error terkait penggunaan `GlobalKey` dengan tipe state yang tidak ada:

```
lib/widgets/qr_code_scanner_tl_widget.dart:39:19: Error: Type '_QRCameraWrapperState' not found.
  final GlobalKey<_QRCameraWrapperState> _cameraKey = GlobalKey<_QRCameraWrapperState>();
                  ^^^^^^^^^^^^^^^^^^^^^
lib/widgets/qr_code_scanner_tl_widget.dart:39:19: Error: '_QRCameraWrapperState' isn't a type.
  final GlobalKey<_QRCameraWrapperState> _cameraKey = GlobalKey<_QRCameraWrapperState>();
                  ^^^^^^^^^^^^^^^^^^^^^
lib/widgets/qr_code_scanner_tl_widget.dart:39:65: Error: '_QRCameraWrapperState' isn't a type.
  final GlobalKey<_QRCameraWrapperState> _cameraKey = GlobalKey<_QRCameraWrapperState>();
                                                                ^^^^^^^^^^^^^^^^^^^^^
```

Masalah ini terjadi karena:
1. Menggunakan tipe `_QRCameraWrapperState` yang merupakan kelas private (diawali dengan `_`)
2. Kelas private tidak dapat diakses dari file lain
3. `GlobalKey` membutuhkan tipe state yang valid dan dapat diakses

## Solusi yang Diterapkan

### 1. Membuat State Class Menjadi Public

Di `qr_camera_wrapper.dart`, mengubah kelas state yang sebelumnya private menjadi public:

```dart
// Sebelumnya
class _QRCameraWrapperState extends State<QRCameraWrapper> {
  // ...
}

// Setelah diperbaiki
class QRCameraWrapperState extends State<QRCameraWrapper> {
  // ...
}
```

Serta memperbarui metode `createState()` untuk menggunakan kelas public:

```dart
@override
State<QRCameraWrapper> createState() => QRCameraWrapperState();
```

### 2. Mengekspos Metode Public untuk Restart Kamera

Mengubah metode `_forceRestartCamera()` menjadi public untuk memungkinkan pemanggilan dari luar:

```dart
// Sebelumnya (private)
Future<void> _forceRestartCamera() async {
  // ...
}

// Setelah diperbaiki (public)
Future<void> forceRestartCamera() async {
  // ...
}
```

### 3. Menggunakan GlobalKey dengan Tipe yang Benar

Di `qr_code_scanner_tl_widget.dart`, memperbaiki penggunaan GlobalKey:

```dart
// Sebelumnya (tipe tidak valid)
final GlobalKey<_QRCameraWrapperState> _cameraKey = GlobalKey<_QRCameraWrapperState>();

// Setelah diperbaiki (tipe valid)
final GlobalKey<QRCameraWrapperState> _cameraKey = GlobalKey<QRCameraWrapperState>();
```

### 4. Implementasi Pemanggilan Metode via GlobalKey

Menambahkan kode untuk memanggil metode pada state QRCameraWrapper menggunakan GlobalKey:

```dart
// Coba gunakan GlobalKey untuk memanggil metode pada QRCameraWrapper jika tersedia
if (_cameraKey.currentState != null) {
  await _cameraKey.currentState!.forceRestartCamera();
  
  // Tunggu sebentar sebelum mengubah status restarting
  await Future.delayed(Duration(milliseconds: 500));
  
  if (mounted) {
    setState(() {
      _forceRestarting = false;
    });
  }
  return;
}
```

## Manfaat dari Perbaikan

1. **Komunikasi antar widget yang lebih baik**: QRCodeScannerTLWidget sekarang dapat secara langsung memanggil metode pada QRCameraWrapper menggunakan GlobalKey.

2. **Pengelolaan state yang lebih terpadu**: Proses restart kamera sekarang dikelola di satu tempat (QRCameraWrapperState), bukan diduplikasi di beberapa tempat.

3. **Fallback yang robust**: Jika GlobalKey tidak tersedia, tetap ada mekanisme fallback yang akan melakukan restart kamera menggunakan cara lama.

4. **Kode yang lebih maintainable**: Pemisahan tanggung jawab yang lebih jelas antara widget scanner dan wrapper kamera.

## Panduan Penggunaan GlobalKey untuk State Management

Ketika menggunakan GlobalKey untuk mengakses state widget lain, perhatikan hal-hal berikut:

1. **State class harus public**: Kelas state yang ingin diakses harus merupakan kelas public, bukan private (tidak diawali dengan underscore `_`).

2. **Metode yang diakses harus public**: Metode yang akan dipanggil dari luar juga harus public.

3. **Selalu periksa null**: Selalu periksa apakah `currentState` tidak null sebelum mengaksesnya (`if (_cameraKey.currentState != null) { ... }`).

4. **Gunakan dengan bijak**: GlobalKey sebaiknya digunakan dengan hemat, karena dapat membuat hierarki widget menjadi lebih sulit dipahami.

5. **Sediakan fallback**: Selalu sediakan mekanisme fallback jika GlobalKey tidak tersedia atau null. 
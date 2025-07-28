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
  final Key? key;
  final Function(QRViewController) onQRViewCreated;
  final QrScannerOverlayShape? overlay;
  final List<BarcodeFormat>? formatsAllowed;

  const QRView({
    this.key,
    required this.onQRViewCreated,
    this.overlay,
    this.formatsAllowed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Buat controller dummy dan panggil callback
    final dummyController = QRViewController();
    Future.microtask(() => onQRViewCreated(dummyController));
    
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'QR Scanner tidak tersedia di web',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Stub untuk QRViewController
class QRViewController {
  // Buat stream dummy yang tidak pernah mengeluarkan data
  Stream<Barcode> get scannedDataStream => 
      Stream<Barcode>.empty();
  
  void dispose() {}
  void pauseCamera() {}
  void resumeCamera() {}
  Future<void> toggleFlash() async {}
  Future<void> flipCamera() async {}
  Future<void> stopCamera() async {}
}

// Stub untuk QrScannerOverlayShape
class QrScannerOverlayShape {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderRadius = 0,
    this.borderLength = 0,
    this.borderWidth = 0,
    this.cutOutSize = 0,
  });
}

// Stub untuk Barcode
class Barcode {
  final String? code;
  final BarcodeFormat format;

  Barcode({
    this.code,
    this.format = BarcodeFormat.qrcode,
  });
} 
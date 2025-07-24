import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class QRCodeScannerTLWidget extends StatefulWidget {
  final String title;
  final Function(String) onQRCodeDetected;

  const QRCodeScannerTLWidget({
    Key? key,
    required this.title,
    required this.onQRCodeDetected,
  }) : super(key: key);

  @override
  State<QRCodeScannerTLWidget> createState() => _QRCodeScannerTLWidgetState();
}

class _QRCodeScannerTLWidgetState extends State<QRCodeScannerTLWidget> {
  bool _isProcessing = false;
  String _scanResult = '';

  @override
  void initState() {
    super.initState();
    print('🔍 QR Code Scanner TL initialized');
    // Langsung mulai scan saat widget dibuat
    _startScan();
  }

  // Metode untuk memulai pemindaian
  Future<void> _startScan() async {
    if (kIsWeb) {
      // Web tidak didukung untuk scanner ini
      return;
    }
    
    try {
      setState(() {
        _isProcessing = true;
      });
      
      print('🔍 Starting barcode scan...');
      
      // Gunakan flutter_barcode_scanner untuk memindai QR code
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF0000', // Warna garis pemindai
        'Batal', // Teks tombol batal
        true, // Aktifkan flash
        ScanMode.QR, // Mode scan QR code
      );
      
      print('🔍 Scan result: $barcodeScanRes');
      
      // Jika hasil scan bukan "-1" (dibatalkan), proses hasilnya
      if (barcodeScanRes != '-1') {
        setState(() {
          _scanResult = barcodeScanRes;
        });
        
        // Proses hasil scan
        widget.onQRCodeDetected(barcodeScanRes);
        
        // Kembali ke halaman sebelumnya dengan hasil scan
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(barcodeScanRes);
        }
      } else {
        print('🔍 Scan canceled by user');
        // Kembali ke halaman sebelumnya tanpa hasil
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('🚫 Error during scan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat memindai: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
      body: kIsWeb
          ? _buildWebFallback(context)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing)
                    const CircularProgressIndicator(color: Colors.white)
                  else
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 100,
                      color: Colors.white,
                    ),
                  const SizedBox(height: 24),
                  const Text(
                    'Scanner QR Code sedang berjalan...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Scan Ulang'),
                  ),
                ],
              ),
            ),
    );
  }
  
  // Fallback untuk platform web
  Widget _buildWebFallback(BuildContext context) {
    final textController = TextEditingController();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'QR Code Scanner tidak didukung di web browser',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Silakan gunakan aplikasi mobile atau input QR code secara manual',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Paste QR code di sini...',
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  // Process the QR code
                  widget.onQRCodeDetected(textController.text);
                  Navigator.of(context).pop(textController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Proses QR Code'),
            ),
          ],
        ),
      ),
    );
  }
} 
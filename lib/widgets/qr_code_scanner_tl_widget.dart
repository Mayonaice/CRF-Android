import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class QRCodeScannerTLWidget extends StatefulWidget {
  final String title;
  final Function(String) onBarcodeDetected;
  final String? fieldKey;
  final String? fieldLabel;
  final String? sectionId;

  const QRCodeScannerTLWidget({
    Key? key,
    required this.title,
    required this.onBarcodeDetected,
    this.fieldKey,
    this.fieldLabel,
    this.sectionId,
  }) : super(key: key);

  @override
  State<QRCodeScannerTLWidget> createState() => _QRCodeScannerTLWidgetState();
}

class _QRCodeScannerTLWidgetState extends State<QRCodeScannerTLWidget> {
  bool _isScanning = false;
  String _scanResult = '';

  @override
  void initState() {
    super.initState();
    
    // Change to portrait orientation for camera scanning
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    print('🔍 QR Code scanner TL widget initialized');
    
    // Start scanning automatically after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      _startScan();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    
    setState(() {
      _isScanning = true;
    });
    
    try {
      // Start barcode scanning
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#FF6600', // Orange color
        'Cancel',
        true,
        ScanMode.QR,
      );
      
      // Check if scan was cancelled
      if (barcodeScanRes == '-1') {
        print('🔍 Scan cancelled');
        Navigator.of(context).pop(null);
        return;
      }
      
      print('🎯 SCANNER TL: QR code detected: ${barcodeScanRes.length > 50 ? barcodeScanRes.substring(0, 50) + "..." : barcodeScanRes}');
      
      setState(() {
        _scanResult = barcodeScanRes;
      });
      
      // Return to landscape orientation before calling callback
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Call the callback function with the scanned code
      widget.onBarcodeDetected(barcodeScanRes);
      
      // Close the screen
      Navigator.of(context).pop(barcodeScanRes);
      
    } catch (e) {
      print('🚫 SCANNER TL ERROR: $e');
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Scanning Error'),
          content: Text('Failed to scan barcode: ${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(null);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _startScan,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanning)
              CircularProgressIndicator(
                color: Colors.orange,
              )
            else
              ElevatedButton.icon(
                onPressed: _startScan,
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Scan QR Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            SizedBox(height: 20),
            Text(
              'Arahkan kamera ke QR Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
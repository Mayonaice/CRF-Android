import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

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
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _screenOpened = false;
  bool _processingBarcode = false;
  bool _hasFlash = false;
  bool _flashOn = false;
  
  // For handling the result
  StreamSubscription? _subscription;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  void initState() {
    super.initState();
    _screenOpened = false;
    _processingBarcode = false;
    
    // Change to portrait orientation for camera scanning
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    print('🔍 QR Code scanner TL widget initialized');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_hasFlash)
            IconButton(
              icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: () async {
                await controller?.toggleFlash();
                setState(() {
                  _flashOn = !_flashOn;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.orange,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Arahkan kamera ke QR Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    
    // Check if flash is available
    controller.getFlashStatus().then((value) {
      setState(() {
        _hasFlash = value ?? false;
      });
    });
    
    // Listen for scanned data
    _subscription = controller.scannedDataStream.listen((scanData) {
      _processScannedData(scanData);
    });
    
    // Resume camera
    controller.resumeCamera();
  }
  
  void _processScannedData(Barcode scanData) {
    // Avoid processing multiple times
    if (_screenOpened || _processingBarcode || !mounted) return;
    
    // Set processing flag
    setState(() {
      _processingBarcode = true;
    });
    
    try {
      final code = scanData.code ?? '';
      
      if (code.isEmpty) {
        print('🚫 SCANNER TL: Empty barcode content detected');
        setState(() {
          _processingBarcode = false;
        });
        return;
      }
      
      print('🎯 SCANNER TL: QR code detected: ${code.length > 50 ? code.substring(0, 50) + "..." : code}');
      
      // Mark screen as opened
      _screenOpened = true;
      
      // Stop the camera
      controller?.pauseCamera();
      
      // Return to landscape orientation before calling callback
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      
      // Call the callback function with the scanned code
      widget.onBarcodeDetected(code);
      
      // Close the screen
      Navigator.of(context).pop(code);
      
    } catch (e) {
      print('🚫 SCANNER TL ERROR: $e');
      setState(() {
        _processingBarcode = false;
      });
    }
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final String title;
  final Function(String) onBarcodeDetected;
  final bool forceShowCheckmark;

  const BarcodeScannerWidget({
    Key? key,
    required this.title,
    required this.onBarcodeDetected,
    this.forceShowCheckmark = false,
  }) : super(key: key);

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _screenOpened = false;

  @override
  void initState() {
    super.initState();
    _screenOpened = false;
    
    // Change to portrait orientation for camera scanning
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 600;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            // Return to landscape orientation before closing
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await controller?.toggleFlash();
            },
            icon: const Icon(
              Icons.flash_on,
              color: Colors.white,
            ),
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
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: isSmallScreen ? 25 : 30,
                borderWidth: isSmallScreen ? 8 : 10,
                cutOutSize: isSmallScreen ? 250 : 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: Center(
                child: Text(
                  'Arahkan kamera ke barcode/QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
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
    controller.scannedDataStream.listen((scanData) {
      if (!_screenOpened && scanData.code != null && scanData.code!.isNotEmpty) {
        _screenOpened = true;
        // print('✅ QR Code Scanner: Barcode detected: ${scanData.code}');
        
        // Stop the camera safely
        try {
          controller.pauseCamera();
        } catch (e) {
          // print('Error pausing camera: $e');
        }
        
        // Return to landscape orientation before calling callback
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        
        // Call the callback function with the scanned code
        widget.onBarcodeDetected(scanData.code!);
        
        // Close the scanner screen
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  @override
  void dispose() {
    // Ensure we return to landscape orientation when disposing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // try {
    //   controller?.dispose();
    // } catch (e) {
    //   print('Error disposing QR controller: $e');
    // }
    
    super.dispose();
  }
}

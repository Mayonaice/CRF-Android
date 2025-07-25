import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Import only QrMobileVision for API access, not the camera widget
import 'package:qr_mobile_vision/qr_mobile_vision.dart';

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
  bool _qrFound = false;
  String _scanResult = '';
  bool _hasPermission = false;
  bool _loading = true;
  bool _cameraStarted = false;

  @override
  void initState() {
    super.initState();
    _isScanning = false;
    _qrFound = false;
    
    // Change to portrait orientation for camera scanning
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Check for camera permission
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      // Check camera permission by starting with minimal required parameters
      await QrMobileVision.start(
        qrCodeHandler: (String? code) {
          // Empty handler since we're just checking permission
          if (code != null) {
            QrMobileVision.stop();
          }
        },
        // Required parameters from updated API
        width: 300,
        height: 300,
        formats: const [BarcodeFormats.QR_CODE],
      );
      
      setState(() {
        _hasPermission = true;
        _loading = false;
      });
      
      // Stop immediately, we'll start again in build
      await QrMobileVision.stop();
      
    } catch (e) {
      print('Error checking camera permission: $e');
      setState(() {
        _hasPermission = false;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_cameraStarted) {
      QrMobileVision.stop();
    }
    super.dispose();
  }

  void _handleCode(String? code) {
    if (_qrFound || code == null || code.isEmpty) return;
    
    setState(() {
      _qrFound = true;
      _scanResult = code;
      _isScanning = false;
    });
    
    print('🎯 QR SCANNER TL: QR code detected: ${code.length > 50 ? code.substring(0, 50) + "..." : code}');
    
    // Return to landscape orientation before calling callback
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Call the callback function with the scanned code
    widget.onBarcodeDetected(code);
    
    // Stop the camera
    if (_cameraStarted) {
      QrMobileVision.stop();
      _cameraStarted = false;
    }
    
    // Close the screen after a short delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop(code);
      }
    });
  }

  void _showManualInputDialog() {
    final textController = TextEditingController();
    
    showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manual QR Code Input'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter or paste QR code content:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Paste QR code here...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  _handleCode(textController.text);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('QR code cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _startScanning() {
    if (_hasPermission && !_cameraStarted) {
      QrMobileVision.start(
        qrCodeHandler: _handleCode,
        formats: const [BarcodeFormats.QR_CODE],
        width: MediaQuery.of(context).size.width.toInt(),
        height: MediaQuery.of(context).size.height.toInt(),
      );
      setState(() {
        _cameraStarted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPermission && !_cameraStarted && !_qrFound) {
      // Start scanning when widget is built and we have permission
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScanning());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.text_fields),
            onPressed: _showManualInputDialog,
            tooltip: 'Manual Input',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _hasPermission
                      ? _CustomQRCameraView(
                          isScanning: _cameraStarted,
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.no_photography,
                                size: 64,
                                color: Colors.red,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Camera permission denied',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _loading = true;
                                  });
                                  _checkPermission();
                                },
                                child: Text('Request Permission'),
                              ),
                            ],
                          ),
                        ),
                ),
                SafeArea(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    color: Colors.black87,
                    child: Text(
                      'Arahkan kamera ke QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Custom camera view widget that avoids using the conflicting QrCamera widget
class _CustomQRCameraView extends StatelessWidget {
  final bool isScanning;

  const _CustomQRCameraView({
    Key? key,
    required this.isScanning,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isScanning) {
      return Center(child: Text('Starting camera...'));
    }
    
    // This is a placeholder for the camera view
    // QrMobileVision.start has already been called to start the camera
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // The camera preview is shown by the native platform view
          // We just need to provide a placeholder here
          Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ),
          // Scan animation
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.green,
                  width: 2.0,
                ),
              ),
              child: Center(
                child: Text(
                  'Scanning...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
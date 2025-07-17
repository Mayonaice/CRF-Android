import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// GLOBAL STREAM FOR BARCODE SCANNING RESULTS
class BarcodeResultStream {
  static final BarcodeResultStream _instance = BarcodeResultStream._internal();
  factory BarcodeResultStream() => _instance;
  BarcodeResultStream._internal();

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  void addResult({
    required String barcode,
    required String fieldKey,
    required String label,
  }) {
    _controller.add({
      'barcode': barcode,
      'fieldKey': fieldKey,
      'label': label,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    print('🎯 STREAM: Barcode result added to stream - $fieldKey: $barcode');
  }

  void dispose() {
    _controller.close();
  }
}

class BarcodeScannerWidget extends StatefulWidget {
  final String title;
  final Function(String) onBarcodeDetected;
  final bool forceShowCheckmark; // Add this parameter
  final String? fieldKey; // NEW: Add field key to identify which field is being scanned
  final String? fieldLabel; // NEW: Add field label

  const BarcodeScannerWidget({
    Key? key,
    required this.title,
    required this.onBarcodeDetected,
    this.forceShowCheckmark = false, // Changed default to false
    this.fieldKey,
    this.fieldLabel,
  }) : super(key: key);

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  MobileScannerController cameraController = MobileScannerController(
    // Configure camera for portrait orientation during scanning
    facing: CameraFacing.back,
    torchEnabled: false,
    useNewCameraSelector: true,
  );
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
    // For portrait mode, adjust the responsive check
    final isSmallScreen = size.height < 600; // Changed from width to height for portrait
    
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
            color: Colors.white,
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                if (state == null) {
                  return const Icon(Icons.flash_off, color: Colors.grey);
                }
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            iconSize: isSmallScreen ? 24 : 32,
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview with proper orientation for portrait
          Container(
            width: double.infinity,
            height: double.infinity,
            child: MobileScanner(
              controller: cameraController,
              onDetect: _foundBarcode,
              fit: BoxFit.cover, // Ensure camera fills the screen properly
            ),
          ),
          
          // Overlay with scanning frame - adjusted for portrait
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: isSmallScreen ? 25 : 30,
                borderWidth: isSmallScreen ? 8 : 10,
                cutOutSize: isSmallScreen ? 250 : 300, // Larger for portrait
                overlayColor: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          
          // Instructions overlay
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Arahkan kamera ke barcode${widget.fieldLabel != null ? " untuk ${widget.fieldLabel}" : ""}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _foundBarcode(BarcodeCapture barcodeCapture) {
    if (!_screenOpened && mounted) {
      final List<Barcode> barcodes = barcodeCapture.barcodes;
      if (barcodes.isNotEmpty) {
        final String code = barcodes.first.displayValue ?? barcodes.first.rawValue ?? '';
        if (code.isNotEmpty) {
          _screenOpened = true;
          print('🎯 SCANNER: Barcode detected: $code for field: ${widget.fieldKey}');
          
          // Stop the camera safely
          try {
            cameraController.stop();
          } catch (e) {
            print('Error stopping camera: $e');
          }
          
          // Return to landscape orientation before calling callback
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          
          // ADD TO STREAM INSTEAD OF RELYING ON NAVIGATION
          if (widget.fieldKey != null) {
            BarcodeResultStream().addResult(
              barcode: code,
              fieldKey: widget.fieldKey!,
              label: widget.fieldLabel ?? widget.title,
            );
          }
          
          // Call the callback function with the scanned code
          widget.onBarcodeDetected(code);
          
          // Close the scanner screen
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(code);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    // Ensure we return to landscape orientation when disposing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    try {
      cameraController.dispose();
    } catch (e) {
      print('Error disposing camera controller: $e');
    }
    super.dispose();
  }
}

// Custom path for the barcode scanner overlay
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    required this.borderColor,
    required this.borderWidth,
    required this.overlayColor,
    required this.borderRadius,
    required this.borderLength,
    required this.cutOutSize,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.left + cutOutSize, rect.top)
      ..lineTo(rect.left + cutOutSize, rect.top + borderLength)
      ..lineTo(rect.left + borderLength, rect.top + borderLength)
      ..lineTo(rect.left + borderLength, rect.top + cutOutSize)
      ..lineTo(rect.left, rect.top + cutOutSize)
      ..lineTo(rect.left, rect.bottom);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mCutOutWidth = cutOutSize < width ? cutOutSize : width - borderOffset;
    final mCutOutHeight = cutOutSize < height ? cutOutSize : height - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final mCutOutRect = Rect.fromLTWH(
      rect.left + (width - mCutOutWidth) / 2 + borderOffset,
      rect.top + (height - mCutOutHeight) / 2 + borderOffset,
      mCutOutWidth - borderOffset * 2,
      mCutOutHeight - borderOffset * 2,
    );

    canvas
      ..saveLayer(
        rect,
        backgroundPaint,
      )
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          mCutOutRect,
          Radius.circular(borderRadius),
        ),
        backgroundPaint..blendMode = BlendMode.clear,
      )
      ..restore();

    // Draw borders
    final _borderLength = math.min(mCutOutHeight, mCutOutWidth) / 4;

    // Top left
    canvas.drawPath(
      Path()
        ..moveTo(mCutOutRect.left, mCutOutRect.top + _borderLength)
        ..lineTo(mCutOutRect.left, mCutOutRect.top)
        ..lineTo(mCutOutRect.left + _borderLength, mCutOutRect.top),
      borderPaint,
    );

    // Top right
    canvas.drawPath(
      Path()
        ..moveTo(mCutOutRect.right - _borderLength, mCutOutRect.top)
        ..lineTo(mCutOutRect.right, mCutOutRect.top)
        ..lineTo(mCutOutRect.right, mCutOutRect.top + _borderLength),
      borderPaint,
    );

    // Bottom right
    canvas.drawPath(
      Path()
        ..moveTo(mCutOutRect.right, mCutOutRect.bottom - _borderLength)
        ..lineTo(mCutOutRect.right, mCutOutRect.bottom)
        ..lineTo(mCutOutRect.right - _borderLength, mCutOutRect.bottom),
      borderPaint,
    );

    // Bottom left
    canvas.drawPath(
      Path()
        ..moveTo(mCutOutRect.left + _borderLength, mCutOutRect.bottom)
        ..lineTo(mCutOutRect.left, mCutOutRect.bottom)
        ..lineTo(mCutOutRect.left, mCutOutRect.bottom - _borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
        borderColor: borderColor,
        borderWidth: borderWidth,
        overlayColor: overlayColor,
        borderRadius: borderRadius,
        borderLength: borderLength,
        cutOutSize: cutOutSize,
      );
}

 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final String title;
  final Function(String) onBarcodeDetected;
  final bool forceShowCheckmark; // Add this parameter

  const BarcodeScannerWidget({
    Key? key,
    required this.title,
    required this.onBarcodeDetected,
    this.forceShowCheckmark = true, // Default to true
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
            onPressed: () => cameraController.toggleTorch(),
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
          ),
          IconButton(
            onPressed: () => cameraController.switchCamera(),
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front, color: Colors.white);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear, color: Colors.white);
                }
              },
            ),
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
              ),
            ),
          ),
          
          // Instructions - responsive positioning for portrait
          Positioned(
            bottom: isSmallScreen ? 80 : 120,
            left: isSmallScreen ? 10 : 20,
            right: isSmallScreen ? 10 : 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 15 : 20),
              child: Card(
                color: Colors.white.withOpacity(0.9),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        size: isSmallScreen ? 40 : 48,
                        color: Colors.blue[600],
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      Text(
                        'Arahkan kamera ke barcode',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Text(
                        'Barcode akan otomatis terdeteksi dan mengisi field',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
          print('Barcode detected: $code');
          
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
          
          // Call the callback function with the scanned code
          widget.onBarcodeDetected(code);
          
          // If forceShowCheckmark is true, we let the callback handle navigation
          if (!widget.forceShowCheckmark) {
            // Close the scanner screen safely
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
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

// Custom overlay shape for scanner frame
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

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
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
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

    // Draw corner borders
    final path = Path()
      // Top left
      ..moveTo(mCutOutRect.left - borderOffset, mCutOutRect.top - borderOffset + borderLength)
      ..lineTo(mCutOutRect.left - borderOffset, mCutOutRect.top - borderOffset + borderRadius)
      ..quadraticBezierTo(
        mCutOutRect.left - borderOffset,
        mCutOutRect.top - borderOffset,
        mCutOutRect.left - borderOffset + borderRadius,
        mCutOutRect.top - borderOffset,
      )
      ..lineTo(mCutOutRect.left - borderOffset + borderLength, mCutOutRect.top - borderOffset)
      
      // Top right
      ..moveTo(mCutOutRect.right + borderOffset - borderLength, mCutOutRect.top - borderOffset)
      ..lineTo(mCutOutRect.right + borderOffset - borderRadius, mCutOutRect.top - borderOffset)
      ..quadraticBezierTo(
        mCutOutRect.right + borderOffset,
        mCutOutRect.top - borderOffset,
        mCutOutRect.right + borderOffset,
        mCutOutRect.top - borderOffset + borderRadius,
      )
      ..lineTo(mCutOutRect.right + borderOffset, mCutOutRect.top - borderOffset + borderLength)
      
      // Bottom right
      ..moveTo(mCutOutRect.right + borderOffset, mCutOutRect.bottom + borderOffset - borderLength)
      ..lineTo(mCutOutRect.right + borderOffset, mCutOutRect.bottom + borderOffset - borderRadius)
      ..quadraticBezierTo(
        mCutOutRect.right + borderOffset,
        mCutOutRect.bottom + borderOffset,
        mCutOutRect.right + borderOffset - borderRadius,
        mCutOutRect.bottom + borderOffset,
      )
      ..lineTo(mCutOutRect.right + borderOffset - borderLength, mCutOutRect.bottom + borderOffset)
      
      // Bottom left
      ..moveTo(mCutOutRect.left - borderOffset + borderLength, mCutOutRect.bottom + borderOffset)
      ..lineTo(mCutOutRect.left - borderOffset + borderRadius, mCutOutRect.bottom + borderOffset)
      ..quadraticBezierTo(
        mCutOutRect.left - borderOffset,
        mCutOutRect.bottom + borderOffset,
        mCutOutRect.left - borderOffset,
        mCutOutRect.bottom + borderOffset - borderRadius,
      )
      ..lineTo(mCutOutRect.left - borderOffset, mCutOutRect.bottom + borderOffset - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
} 
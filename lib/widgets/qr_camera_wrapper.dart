import 'package:flutter/material.dart';
import 'package:qr_mobile_vision/qr_mobile_vision.dart';

/// Wrapper class untuk QR Camera yang mengatasi konflik class Preview
/// dengan menggunakan implementasi custom sendiri
class QRCameraWrapper extends StatefulWidget {
  final Function(String) qrCodeCallback;
  final List<BarcodeFormats> formats;
  final BoxFit fit;
  final Widget Function(BuildContext)? notStartedBuilder;
  final Widget Function(BuildContext, Object)? onError;

  const QRCameraWrapper({
    Key? key,
    required this.qrCodeCallback,
    this.formats = const [BarcodeFormats.QR_CODE],
    this.fit = BoxFit.cover,
    this.notStartedBuilder,
    this.onError,
  }) : super(key: key);

  @override
  State<QRCameraWrapper> createState() => _QRCameraWrapperState();
}

class _QRCameraWrapperState extends State<QRCameraWrapper> {
  bool _isStarted = false;
  bool _hasError = false;
  String _errorMessage = '';
  double _previewWidth = 100;
  double _previewHeight = 100;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  @override
  void dispose() {
    QrMobileVision.stop();
    super.dispose();
  }

  Future<void> _startCamera() async {
    _hasError = false;
    setState(() {
      _isStarted = false;
    });

    try {
      await QrMobileVision.start(
        qrCodeHandler: (String? code) {
          if (code != null && code.isNotEmpty) {
            widget.qrCodeCallback(code);
          }
        },
        formats: widget.formats,
        width: _previewWidth.toInt(),
        height: _previewHeight.toInt(),
      );

      setState(() {
        _isStarted = true;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update preview size based on screen size
    final size = MediaQuery.of(context).size;
    _previewWidth = size.width;
    _previewHeight = size.height;

    if (_hasError) {
      return widget.onError != null
          ? widget.onError!(context, _errorMessage)
          : Center(
              child: Text(
                'Camera error: $_errorMessage',
                style: TextStyle(color: Colors.red),
              ),
            );
    }

    if (!_isStarted) {
      return widget.notStartedBuilder != null
          ? widget.notStartedBuilder!(context)
          : Center(child: CircularProgressIndicator());
    }

    // For camera preview, we're using a simple Container as placeholder
    // since QrMobileVision handles the camera preview internally via platform views
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Viewfinder guide
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
            ),
          ),
          // Scanning animation (optional)
          Positioned(
            bottom: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Scanning...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
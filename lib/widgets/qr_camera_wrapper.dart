import 'dart:async';
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
  int _retryCount = 0;
  Timer? _initTimeoutTimer;
  Timer? _retryTimer;
  bool _isInitializing = false;
  
  @override
  void initState() {
    super.initState();
    // Tunda inisialisasi kamera sedikit untuk menghindari race condition
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _startCamera();
      }
    });
  }

  @override
  void dispose() {
    _cancelTimers();
    QrMobileVision.stop();
    super.dispose();
  }
  
  void _cancelTimers() {
    _initTimeoutTimer?.cancel();
    _retryTimer?.cancel();
  }

  Future<void> _startCamera() async {
    if (_isInitializing) return;
    
    _isInitializing = true;
    _hasError = false;
    
    if (mounted) {
      setState(() {
        _isStarted = false;
      });
    }
    
    // Set timeout untuk inisialisasi kamera (5 detik)
    _initTimeoutTimer = Timer(Duration(seconds: 5), () {
      if (!_isStarted && mounted) {
        print('Camera initialization timed out. Retrying...');
        _retryStartCamera();
      }
    });

    try {
      // Pastikan mendapatkan ukuran layar yang benar
      final size = MediaQuery.of(context).size;
      _previewWidth = size.width;
      _previewHeight = size.height;
      
      // Log untuk debug
      print('Starting QR scanner with size: $_previewWidth x $_previewHeight');
      
      await QrMobileVision.stop(); // Pastikan tidak ada instance yang berjalan
      
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

      _initTimeoutTimer?.cancel();
      _isInitializing = false;
      
      if (mounted) {
        setState(() {
          _isStarted = true;
          _retryCount = 0; // Reset retry count on success
        });
      }
      
      print('QR scanner started successfully');
    } catch (e) {
      _initTimeoutTimer?.cancel();
      _isInitializing = false;
      
      print('Error starting camera: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
      
      // Auto retry if failed
      _retryStartCamera();
    }
  }
  
  void _retryStartCamera() {
    if (_retryCount >= 3 || !mounted) return; // Max 3 retry attempts
    
    _retryCount++;
    _retryTimer = Timer(Duration(seconds: 1), () {
      if (mounted) {
        print('Retrying camera start (attempt $_retryCount)');
        _startCamera();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.onError != null
              ? widget.onError!(context, _errorMessage)
              : Column(
                  children: [
                    Text(
                      'Camera error',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _errorMessage.length > 100 
                          ? '${_errorMessage.substring(0, 100)}...' 
                          : _errorMessage,
                      style: TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _retryCount = 0;
              _startCamera();
            },
            child: Text('Coba Lagi'),
          ),
        ],
      );
    }

    if (!_isStarted) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.notStartedBuilder != null
                ? widget.notStartedBuilder!(context)
                : CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menginisialisasi kamera...'),
            SizedBox(height: 24),
            if (_retryCount > 0)
              Text(
                'Mencoba ulang: $_retryCount',
                style: TextStyle(color: Colors.amber),
              ),
          ],
        ),
      );
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
          // Viewfinder guide - make it more visible with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.0),
            duration: Duration(seconds: 1),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(),
          ),
          // Scanning animation
          Positioned(
            bottom: 40,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
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
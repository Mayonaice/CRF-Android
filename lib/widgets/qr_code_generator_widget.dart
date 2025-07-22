import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';

class QRCodeGeneratorWidget extends StatefulWidget {
  final String action; // 'PREPARE' or 'RETURN'
  final String idTool;
  final VoidCallback? onExpired;

  const QRCodeGeneratorWidget({
    Key? key,
    required this.action,
    required this.idTool,
    this.onExpired,
  }) : super(key: key);

  @override
  State<QRCodeGeneratorWidget> createState() => _QRCodeGeneratorWidgetState();
}

class _QRCodeGeneratorWidgetState extends State<QRCodeGeneratorWidget> {
  late String _qrData;
  late DateTime _expiryTime;
  Timer? _timer;
  Duration _remainingTime = const Duration(minutes: 5);
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _generateQRCode();
    _startTimer();
  }

  void _generateQRCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _expiryTime = DateTime.now().add(const Duration(minutes: 5));
    // Tambahkan flag untuk bypass NIK validation (nilai 1 berarti bypass diaktifkan)
    _qrData = '${widget.action}|${widget.idTool}|$timestamp|1';
    print('Generated QR Code with bypass enabled: $_qrData');
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (now.isAfter(_expiryTime)) {
        setState(() {
          _isExpired = true;
          _remainingTime = Duration.zero;
        });
        _timer?.cancel();
        if (widget.onExpired != null) {
          widget.onExpired!();
        }
      } else {
        setState(() {
          _remainingTime = _expiryTime.difference(now);
        });
      }
    });
  }

  void _regenerateQRCode() {
    setState(() {
      _isExpired = false;
    });
    _timer?.cancel();
    _generateQRCode();
    _startTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  color: _isExpired ? Colors.grey : Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'QR Code untuk Approve ${widget.action}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isExpired ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // QR Code or Expired Message
            if (_isExpired) ...[
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'QR Code Expired',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Generate ulang untuk\nmembuat QR Code baru',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Active QR Code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Timer and Info
            if (!_isExpired) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Expires in: ${_formatDuration(_remainingTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Info text
              Text(
                'ID Tool: ${widget.idTool}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 4),
              
              const Text(
                'TL dapat scan QR Code ini untuk approve tanpa input NIK & Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
            
            // Regenerate button
            if (_isExpired) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _regenerateQRCode,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Generate QR Code Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
} 
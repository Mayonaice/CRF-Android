import 'package:flutter/material.dart';

// This is a stub implementation for web platform
class QRCodeScannerTLWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'QR Code scanning is not available on web.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Show manual input dialog
                _showManualInputDialog(context);
              },
              child: const Text('Enter QR Code Manually'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showManualInputDialog(BuildContext context) async {
    final textController = TextEditingController();
    
    return showDialog<void>(
      context: context,
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  onBarcodeDetected(textController.text);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(textController.text);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
} 
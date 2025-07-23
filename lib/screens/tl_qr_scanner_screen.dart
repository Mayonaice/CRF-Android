import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../widgets/barcode_scanner_widget.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class TLQRScannerScreen extends StatefulWidget {
  const TLQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<TLQRScannerScreen> createState() => _TLQRScannerScreenState();
}

class _TLQRScannerScreenState extends State<TLQRScannerScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isProcessing = false;
  List<Map<String, dynamic>> _recentScans = [];

  @override
  void initState() {
    super.initState();
    // Force portrait orientation for CRF_TL
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _processQRCode(String qrCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      String action;
      String idTool;
      int timestamp;
      bool bypassNikValidation = false;
      String? tlspvUsername;
      String? tlspvPassword;
      
      // Coba periksa apakah ini format QR terenkripsi
      bool isEncrypted = false;
      try {
        // Coba decode base64 untuk menentukan apakah ini QR terenkripsi
        base64Decode(qrCode);
        isEncrypted = true;
      } catch (e) {
        // Bukan format terenkripsi, gunakan parsing format lama
        isEncrypted = false;
      }
      
      if (isEncrypted) {
        // Ini adalah QR code terenkripsi dengan kredensial TLSPV
        print('Detected encrypted QR code format');
        
        // Dekripsi data QR
        final decryptedData = _authService.decryptDataFromQR(qrCode);
        
        if (decryptedData == null) {
          throw Exception('QR Code tidak valid atau sudah expired');
        }
        
        // Ekstrak data dari QR terenkripsi
        action = decryptedData['action'] as String;
        idTool = decryptedData['idTool'] as String;
        timestamp = decryptedData['timestamp'] as int;
        tlspvUsername = decryptedData['username'] as String?;
        tlspvPassword = decryptedData['password'] as String?;
        bypassNikValidation = true; // Selalu true untuk QR terenkripsi
        
        print('Decrypted QR data: Action=$action, IdTool=$idTool, HasCredentials=${tlspvUsername != null}');
      } else {
        // Format lama: "PREPARE|{idTool}|{timestamp}|{bypassFlag}"
        final parts = qrCode.split('|');
        
        if (parts.length < 3) {
          throw Exception('Format QR Code tidak valid');
        }

        action = parts[0]; // PREPARE or RETURN
        idTool = parts[1];
        timestamp = int.tryParse(parts[2]) ?? 0;
        
        // Check if bypass NIK is enabled (fourth part = "1")
        bypassNikValidation = parts.length > 3 && parts[3] == "1";
        
        print('QR Code parts: Action=$action, IdTool=$idTool, Timestamp=$timestamp, BypassNIK=$bypassNikValidation');
      }
      
      // Validasi timestamp
      if (timestamp == 0) {
        throw Exception('Format timestamp tidak valid');
      }

      // Check if QR code is still valid (within 5 minutes)
      final now = DateTime.now().millisecondsSinceEpoch;
      final qrTime = timestamp;
      final diffMinutes = (now - qrTime) / (1000 * 60);

      if (diffMinutes > 5) {
        throw Exception('QR Code sudah expired (lebih dari 5 menit)');
      }

      // Get current user data for approval
      final userData = await _authService.getUserData();
      String tlNik = userData?['userID'] ?? userData?['nik'] ?? '';
      final tlName = userData?['userName'] ?? '';

      // Jika ada kredensial TLSPV dari QR, gunakan itu
      if (tlspvUsername != null && tlspvPassword != null) {
        print('Using TLSPV credentials from QR code');
        tlNik = tlspvUsername; // Gunakan NIK dari QR
      } 
      // Jika tidak ada kredensial dan tidak ada bypass, tolak
      else if (tlNik.isEmpty && !bypassNikValidation) {
        throw Exception('Data TL tidak ditemukan dan QR tidak mengizinkan scan tanpa NIK');
      }

      // Process based on action type
      if (action == 'PREPARE') {
        await _approvePrepare(idTool, tlNik, tlName, bypassNikValidation, tlspvPassword);
      } else if (action == 'RETURN') {
        await _approveReturn(idTool, tlNik, tlName, bypassNikValidation, tlspvPassword);
      } else {
        throw Exception('Tipe aksi tidak valid: $action');
      }

      // Add to recent scans
      _addToRecentScans(action, idTool, true);

      // Show success message
      _showSuccessDialog(action, idTool);

    } catch (e) {
      // Add to recent scans as failed
      _addToRecentScans('UNKNOWN', qrCode.length > 20 ? qrCode.substring(0, 20) + '...' : qrCode, false, error: e.toString());
      
      // Show error message
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _approvePrepare(String idTool, String tlNik, String tlName, bool bypassNikValidation, String? tlspvPassword) async {
    try {
      print('Approving prepare for ID: $idTool by TL: $tlNik ($tlName), bypassValidation: $bypassNikValidation, hasPassword: ${tlspvPassword != null}');
      
      // Jika password tersedia dari QR code, gunakan untuk validasi TLSPV
      if (tlspvPassword != null) {
        // Validasi TLSPV menggunakan kredensial dari QR code
        final validationResponse = await _apiService.validateTLSupervisor(
          nik: tlNik,
          password: tlspvPassword
        );
        
        if (!validationResponse.success) {
          throw Exception('Validasi TLSPV gagal: ${validationResponse.message}');
        }
        
        print('TLSPV validation successful using credentials from QR code');
      }
      
      // Call the API service to approve prepare data
      final response = await _apiService.approvePrepareWithQR(
        idTool, 
        tlNik
      );
      
      if (!response.success) {
        throw Exception('Approval gagal: ${response.message}');
      }
      
      print('Prepare approved successfully for ID: $idTool by TL: $tlNik ($tlName)');
    } catch (e) {
      print('Error approving prepare: $e');
      throw Exception('Approval gagal: ${e.toString()}');
    }
  }

  Future<void> _approveReturn(String idTool, String tlNik, String tlName, bool bypassNikValidation, String? tlspvPassword) async {
    try {
      print('Approving return for ID: $idTool by TL: $tlNik ($tlName), bypassValidation: $bypassNikValidation, hasPassword: ${tlspvPassword != null}');
      
      // Jika password tersedia dari QR code, gunakan untuk validasi TLSPV
      if (tlspvPassword != null) {
        // Validasi TLSPV menggunakan kredensial dari QR code
        final validationResponse = await _apiService.validateTLSupervisor(
          nik: tlNik,
          password: tlspvPassword
        );
        
        if (!validationResponse.success) {
          throw Exception('Validasi TLSPV gagal: ${validationResponse.message}');
        }
        
        print('TLSPV validation successful using credentials from QR code');
      }
      
      // Call the API service to approve return data with bypass flag
      // For now, we'll simulate the API call
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // In real implementation, this would call the API service
      // Example: await _apiService.approveReturnWithQR(idTool, tlNik, bypassNikValidation: bypassNikValidation);
      
      print('Return approved for ID: $idTool by TL: $tlNik ($tlName)');
    } catch (e) {
      print('Error approving return: $e');
      throw Exception('Approval return gagal: ${e.toString()}');
    }
  }

  void _addToRecentScans(String action, String idTool, bool success, {String? error}) {
    setState(() {
      _recentScans.insert(0, {
        'action': action,
        'idTool': idTool,
        'success': success,
        'timestamp': DateTime.now(),
        'error': error,
      });
      
      // Keep only last 10 scans
      if (_recentScans.length > 10) {
        _recentScans.removeRange(10, _recentScans.length);
      }
    });
  }

  void _showSuccessDialog(String action, String idTool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text('${action == 'PREPARE' ? 'Prepare' : 'Return'} Approved'),
          ],
        ),
        content: Text('$idTool berhasil di-approve melalui QR Code'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerWidget(
          title: 'Scan QR Code TLSPV',
          onBarcodeDetected: _processQRCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Approve TLSPV',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0056A4),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0056A4),
              Color(0xFFA9D0D7),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Main QR Scanner Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // QR Code Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0056A4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        const Text(
                          'QR Code TLSPV Approval',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0056A4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        const Text(
                          'Scan QR Code untuk approve prepare atau return tanpa memasukkan NIK TL dan password',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Scan Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _openQRScanner,
                            icon: _isProcessing 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.qr_code_scanner),
                            label: Text(
                              _isProcessing ? 'Processing...' : 'Scan QR Code',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0056A4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Recent Scans Section
                if (_recentScans.isNotEmpty) ...[
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Recent Approvals',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0056A4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _recentScans.length,
                                itemBuilder: (context, index) {
                                  final scan = _recentScans[index];
                                  return _buildRecentScanItem(scan);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentScanItem(Map<String, dynamic> scan) {
    final success = scan['success'] as bool;
    final action = scan['action'] as String;
    final idTool = scan['idTool'] as String;
    final timestamp = scan['timestamp'] as DateTime;
    final error = scan['error'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: success ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$action: $idTool',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: success ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                if (!success && error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    error,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Keep portrait orientation for CRF_TL
    super.dispose();
  }
} 
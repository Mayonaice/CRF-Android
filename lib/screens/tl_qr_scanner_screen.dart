import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../widgets/barcode_scanner_widget.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/prepare_model.dart';
import '../services/notification_service.dart';

class TLQRScannerScreen extends StatefulWidget {
  const TLQRScannerScreen({Key? key}) : super(key: key);

  @override
  State<TLQRScannerScreen> createState() => _TLQRScannerScreenState();
}

class _TLQRScannerScreenState extends State<TLQRScannerScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  bool _isProcessing = false;
  List<Map<String, dynamic>> _recentScans = [];
  
  // Controllers untuk form kredensial TL
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSavingCredentials = false;

  // Variabel untuk notifikasi ke CRF_OPR
  String? _operatorId;
  String? _operatorName;

  @override
  void initState() {
    super.initState();
    // Force portrait orientation for CRF_TL
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Cek kredensial TL yang tersimpan
    _checkSavedCredentials();
  }
  
  @override
  void dispose() {
    _nikController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Cek kredensial TL yang tersimpan
  Future<void> _checkSavedCredentials() async {
    final credentials = await _authService.getTLSPVCredentials();
    if (credentials != null) {
      print('Found saved TL credentials: username=${credentials['username']}');
    } else {
      print('No saved TL credentials found');
    }
  }
  
  // Simpan kredensial TL
  Future<void> _saveCredentials() async {
    if (_nikController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIK dan Password harus diisi'))
      );
      return;
    }
    
    setState(() {
      _isSavingCredentials = true;
    });
    
    try {
      final success = await _authService.saveTLSPVCredentials(
        _nikController.text.trim(),
        _passwordController.text.trim()
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kredensial TL berhasil disimpan'),
            backgroundColor: Colors.green,
          )
        );
        
        // Clear form
        _nikController.clear();
        _passwordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan kredensial TL'),
            backgroundColor: Colors.red,
          )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        )
      );
    } finally {
      setState(() {
        _isSavingCredentials = false;
      });
    }
  }

  Future<void> _processQRCode(String qrCode) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      String action = '';
      String idTool = '';
      int timestamp = 0;
      List<CatridgeQRData>? catridgeData;
      
      // PENTING: Log QR code awal untuk debugging
      print('Processing QR Code: ${qrCode.length > 20 ? qrCode.substring(0, 20) + "..." : qrCode}');
      
      // Coba periksa apakah ini format QR terenkripsi
      bool isEncrypted = false;
      try {
        // Coba decode base64 untuk menentukan apakah ini QR terenkripsi
        base64Decode(qrCode);
        isEncrypted = true;
        print('QR code appears to be encrypted (valid base64)');
      } catch (e) {
        // Bukan format terenkripsi, gunakan parsing format lama
        isEncrypted = false;
        print('QR code is not encrypted (not valid base64): $e');
      }
      
      if (isEncrypted) {
        // Ini adalah QR code terenkripsi dengan data catridge
        print('Detected encrypted QR code format');
        
        // Dekripsi data QR
        final decryptedData = _authService.decryptDataFromQR(qrCode);
        print('Decrypted data: ${decryptedData != null ? "success" : "failed"}');
        
        if (decryptedData == null) {
          throw Exception('QR Code tidak valid atau sudah expired');
        }
        
        // TAMBAHAN: Log semua keys dalam decryptedData untuk debugging
        print('Decrypted data keys: ${decryptedData.keys.toList()}');
        
        // Ekstrak data dari QR terenkripsi dengan validasi tipe data
        try {
          // PERBAIKAN: Ekstraksi data dengan lebih eksplisit dan pengecekan yang lebih ketat
          if (decryptedData.containsKey('action')) {
            action = decryptedData['action'].toString();
            print('Extracted action: $action');
          } else {
            print('ERROR: action key missing in decrypted data');
            throw Exception('QR Code tidak memiliki informasi action');
          }
          
          if (decryptedData.containsKey('timestamp')) {
            timestamp = int.tryParse(decryptedData['timestamp'].toString()) ?? 0;
            print('Extracted timestamp: $timestamp');
          } else {
            print('ERROR: timestamp key missing in decrypted data');
            timestamp = 0;
          }
          
          // PERBAIKAN: Untuk flow baru, kita hanya perlu data catridge dari QR
          // Kredensial TL akan diambil dari login user CRF_TL
          
          // Cek apakah ada data catridge (format baru)
          if (decryptedData.containsKey('catridges')) {
            print('QR contains catridge data');
            
            // Parse catridge data
            final catridges = decryptedData['catridges'];
            if (catridges is List) {
              catridgeData = [];
              
              for (var item in catridges) {
                if (item is Map<String, dynamic>) {
                  try {
                    final catridge = CatridgeQRData(
                      idTool: item['idTool'] as int,
                      bagCode: item['bagCode'] as String,
                      catridgeCode: item['catridgeCode'] as String,
                      sealCode: item['sealCode'] as String,
                      catridgeSeal: item['catridgeSeal'] as String,
                      denomCode: item['denomCode'] as String,
                      qty: item['qty'] as String,
                      userInput: item['userInput'] as String,
                      sealReturn: item['sealReturn'] as String,
                      typeCatridgeTrx: item['typeCatridgeTrx'] as String,
                      tableCode: item['tableCode'] as String,
                      warehouseCode: item['warehouseCode'] as String,
                      operatorId: item['operatorId'] as String,
                      operatorName: item['operatorName'] as String,
                    );
                    
                    // Simpan operator ID dan name untuk notifikasi
                    _operatorId = item['operatorId'] as String;
                    _operatorName = item['operatorName'] as String;
                    
                    catridgeData.add(catridge);
                  } catch (e) {
                    print('Error parsing catridge data: $e');
                  }
                }
              }
              
              print('Parsed ${catridgeData.length} catridge items from QR');
              
              // Ambil idTool dari catridge pertama
              if (catridgeData.isNotEmpty) {
                idTool = catridgeData[0].idTool.toString();
                print('Using idTool from catridge data: $idTool');
              } else {
                throw Exception('Tidak ada data catridge yang valid dalam QR');
              }
            } else {
              throw Exception('Format data catridge tidak valid');
            }
          } else {
            // Format lama tanpa data catridge
            if (decryptedData.containsKey('idTool')) {
              idTool = decryptedData['idTool'].toString();
              print('Using old QR format with idTool: $idTool');
            } else {
              print('ERROR: idTool key missing in decrypted data');
              throw Exception('QR Code tidak memiliki informasi ID Tool');
            }
          }
          
          print('Decrypted QR data summary: Action=$action, IdTool=$idTool, HasCatridges=${catridgeData != null && catridgeData.isNotEmpty}');
          
          // Validasi data yang diekstrak
          if (action.isEmpty) {
            print('ERROR: Action is empty after extraction');
            throw Exception('QR Code tidak memiliki informasi action');
          }
          
          if (idTool.isEmpty) {
            print('ERROR: IdTool is empty after extraction');
            throw Exception('QR Code tidak memiliki informasi ID Tool');
          }
          
          if (timestamp == 0) {
            print('ERROR: Timestamp is 0 or invalid after extraction');
            throw Exception('QR Code tidak memiliki timestamp yang valid');
          }
        } catch (e) {
          print('Error extracting data from QR: $e');
          throw Exception('Format data QR tidak valid: ${e.toString()}');
        }
      } else {
        // Format lama: "PREPARE|{idTool}|{timestamp}|{bypassFlag}"
        final parts = qrCode.split('|');
        
        if (parts.length < 3) {
          throw Exception('Format QR Code tidak valid');
        }

        action = parts[0]; // PREPARE or RETURN
        idTool = parts[1];
        timestamp = int.tryParse(parts[2]) ?? 0;
        
        print('QR Code parts: Action=$action, IdTool=$idTool, Timestamp=$timestamp');
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

      // Get user data for TL name
      final userData = await _authService.getUserData();
      final tlName = userData?['userName'] ?? '';
      final tlNik = userData?['userID'] ?? userData?['nik'] ?? '';
      
      // Debug log untuk memastikan nilai tlNik tidak kosong
      print('TL NIK being used: "$tlNik", isEmpty=${tlNik.isEmpty}, length=${tlNik.length}');
      
      if (tlNik.isEmpty) {
        throw Exception('NIK TL tidak boleh kosong (tidak ditemukan di data login)');
      }

      // Process based on action type
      if (action == 'PREPARE') {
        if (catridgeData != null && catridgeData.isNotEmpty) {
          // Format baru: proses data catridge langsung
          await _approveAndProcessCatridges(idTool, tlNik, tlName, null, catridgeData);
        } else {
          // Format lama: hanya approve prepare
          await _approvePrepare(idTool, tlNik, tlName, false, null);
        }
      } else if (action == 'RETURN') {
        await _approveReturn(idTool, tlNik, tlName, false, null);
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

  // Fungsi baru untuk memproses data catridge sekaligus
  Future<void> _approveAndProcessCatridges(String idTool, String tlNik, String tlName, String? tlspvPassword, List<CatridgeQRData> catridges) async {
    try {
      print('Processing ${catridges.length} catridges for ID: $idTool by TL: $tlNik ($tlName)');
      
      // PERBAIKAN: Gunakan kredensial login CRF_TL, bukan dari QR
      final userData = await _authService.getUserData();
      final currentUser = userData?['nik'] ?? userData?['userID'] ?? 'UNKNOWN';
      final currentUserName = userData?['userName'] ?? '';
      
      // Dapatkan kredensial TL dari data login, bukan dari QR
      final tlCredentials = await _authService.getTLSPVCredentials();
      
      if (tlCredentials == null || 
          !tlCredentials.containsKey('username') || 
          !tlCredentials.containsKey('password') ||
          tlCredentials['username'] == null ||
          tlCredentials['password'] == null) {
        throw Exception('Kredensial TL tidak tersedia. Silakan login kembali.');
      }
      
      final tlNikFromLogin = tlCredentials['username'].toString();
      final tlPasswordFromLogin = tlCredentials['password'].toString();
      
      print('Using TL credentials from login: $tlNikFromLogin');
      
      // Validasi nilai NIK
      if (tlNikFromLogin.isEmpty) {
        throw Exception('NIK TL tidak boleh kosong');
      }
      
      // Pastikan NIK dan password bersih dari whitespace
      final cleanNik = tlNikFromLogin.trim();
      final cleanPassword = tlPasswordFromLogin.trim();
      
      // Step 1: Validasi TL Supervisor credentials dan role - sama seperti flow manual
      print('=== STEP 1: VALIDATE TL SUPERVISOR ===');
      final validationResponse = await _apiService.validateTLSupervisor(
        nik: cleanNik,
        password: cleanPassword
      );
      
      if (!validationResponse.success || validationResponse.data?.validationStatus != 'SUCCESS') {
        throw Exception('Validasi TLSPV gagal: ${validationResponse.message}');
      }
      
      print('TLSPV validation successful: ${validationResponse.data?.userName} (${validationResponse.data?.userRole})');
      
      // Pastikan idTool valid (hilangkan spasi dan karakter non-alfanumerik)
      String cleanIdTool = idTool.trim();
      int idToolInt;
      try {
        idToolInt = int.parse(cleanIdTool);
      } catch (e) {
        throw Exception('Format ID Tool tidak valid: $cleanIdTool');
      }
      
      // Dapatkan data user saat ini untuk parameter tambahan
      final tableCode = catridges[0].tableCode; // Gunakan tableCode dari catridge pertama
      final warehouseCode = catridges[0].warehouseCode; // Gunakan warehouseCode dari catridge pertama
      
      // Step 2: Update Planning API - sama seperti flow manual
      print('=== STEP 2: UPDATE PLANNING ===');
      print('Calling updatePlanning with: idTool=$idToolInt, cashierCode=$currentUser, spvTLCode=$cleanNik, tableCode=$tableCode');
      
      final planningResponse = await _apiService.updatePlanning(
        idTool: idToolInt,
        cashierCode: currentUser,
        spvTLCode: cleanNik,
        tableCode: tableCode,
        warehouseCode: warehouseCode,
      );
      
      if (!planningResponse.success) {
        throw Exception('Update planning gagal: ${planningResponse.message}');
      }
      
      print('Planning update success for ID: $idTool by TL: $cleanNik ($currentUserName)');
      
      // Step 3: Insert ATM Catridge untuk setiap item catridge
      print('=== STEP 3: INSERT ATM CATRIDGE ===');
      List<String> successMessages = [];
      List<String> errorMessages = [];
      
      for (var catridge in catridges) {
        try {
          print('Processing catridge: ${catridge.catridgeCode} (${catridge.typeCatridgeTrx})');
          
          final catridgeResponse = await _apiService.insertAtmCatridge(
            idTool: catridge.idTool,
            bagCode: catridge.bagCode,
            catridgeCode: catridge.catridgeCode,
            sealCode: catridge.sealCode,
            catridgeSeal: catridge.catridgeSeal,
            denomCode: catridge.denomCode,
            qty: catridge.qty,
            userInput: currentUser, // Gunakan user TL sebagai userInput
            sealReturn: catridge.sealReturn,
            typeCatridgeTrx: catridge.typeCatridgeTrx,
          );
          
          if (catridgeResponse.success) {
            successMessages.add('${catridge.catridgeCode}: ${catridgeResponse.message}');
            print('Catridge ${catridge.catridgeCode} inserted successfully');
          } else {
            errorMessages.add('${catridge.catridgeCode}: ${catridgeResponse.message}');
            print('Error inserting catridge ${catridge.catridgeCode}: ${catridgeResponse.message}');
          }
        } catch (e) {
          errorMessages.add('${catridge.catridgeCode}: ${e.toString()}');
          print('Exception inserting catridge ${catridge.catridgeCode}: $e');
        }
      }
      
      // Step 4: Kirim notifikasi ke CRF_OPR (tidak menggunakan FCM)
      if (_operatorId != null && _operatorId!.isNotEmpty) {
        print('=== STEP 4: SEND NOTIFICATION TO CRF_OPR ===');
        try {
          await _notificationService.sendNotification(
            idTool: idTool,
            action: 'PREPARE_APPROVED',
            status: 'SUCCESS',
            message: 'Prepare dengan ID: $idTool telah berhasil diapprove oleh TL: $currentUserName',
            fromUser: currentUser,
            toUser: _operatorId!,
            additionalData: {
              'successCount': successMessages.length,
              'errorCount': errorMessages.length,
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
          
          print('Notification sent to CRF_OPR: ${_operatorId}');
        } catch (e) {
          print('Error sending notification: $e');
        }
      } else {
        print('Cannot send notification: Operator ID not available');
      }
      
      // Log hasil
      print('Catridge insertion results:');
      print('Success: ${successMessages.length}');
      print('Errors: ${errorMessages.length}');
      
      if (errorMessages.isNotEmpty) {
        print('Error messages:');
        for (var error in errorMessages) {
          print('- $error');
        }
      }
      
      // Jika ada error, tampilkan pesan warning
      if (errorMessages.isNotEmpty) {
        _showWarningDialog(
          'Sebagian Catridge Gagal',
          'Berhasil: ${successMessages.length}, Gagal: ${errorMessages.length}\n\nDetail error:\n${errorMessages.join('\n')}'
        );
      }
    } catch (e) {
      print('Error processing catridges: $e');
      throw Exception('Proses catridge gagal: ${e.toString()}');
    }
  }

  Future<void> _approvePrepare(String idTool, String tlNik, String tlName, bool bypassNikValidation, String? tlspvPassword) async {
    try {
      print('Approving prepare for ID: $idTool by TL: $tlNik ($tlName), bypassValidation: $bypassNikValidation, hasPassword: ${tlspvPassword != null}');
      
      // PERBAIKAN: Gunakan kredensial login CRF_TL, bukan dari QR
      final userData = await _authService.getUserData();
      final currentUser = userData?['nik'] ?? userData?['userID'] ?? 'UNKNOWN';
      final currentUserName = userData?['userName'] ?? '';
      
      // Dapatkan kredensial TL dari data login, bukan dari QR
      final tlCredentials = await _authService.getTLSPVCredentials();
      
      if (tlCredentials == null || 
          !tlCredentials.containsKey('username') || 
          !tlCredentials.containsKey('password') ||
          tlCredentials['username'] == null ||
          tlCredentials['password'] == null) {
        throw Exception('Kredensial TL tidak tersedia. Silakan login kembali.');
      }
      
      final tlNikFromLogin = tlCredentials['username'].toString();
      final tlPasswordFromLogin = tlCredentials['password'].toString();
      
      print('Using TL credentials from login: $tlNikFromLogin');
      
      // Validasi nilai NIK
      if (tlNikFromLogin.isEmpty) {
        throw Exception('NIK TL tidak boleh kosong');
      }
      
      // Pastikan NIK dan password bersih dari whitespace
      final cleanNik = tlNikFromLogin.trim();
      final cleanPassword = tlPasswordFromLogin.trim();
      
      // Step 1: Validasi TL Supervisor credentials dan role - sama seperti flow manual
      print('=== STEP 1: VALIDATE TL SUPERVISOR ===');
      final validationResponse = await _apiService.validateTLSupervisor(
        nik: cleanNik,
        password: cleanPassword
      );
      
      if (!validationResponse.success || validationResponse.data?.validationStatus != 'SUCCESS') {
        throw Exception('Validasi TLSPV gagal: ${validationResponse.message}');
      }
      
      print('TLSPV validation successful: ${validationResponse.data?.userName} (${validationResponse.data?.userRole})');
      
      // Pastikan idTool valid (hilangkan spasi dan karakter non-alfanumerik)
      String cleanIdTool = idTool.trim();
      int idToolInt;
      try {
        idToolInt = int.parse(cleanIdTool);
      } catch (e) {
        throw Exception('Format ID Tool tidak valid: $cleanIdTool');
      }
      
      // Dapatkan data user saat ini untuk parameter tambahan
      final tableCode = userData?['tableCode'] ?? 'DEFAULT';
      final warehouseCode = userData?['warehouseCode'] ?? 'Cideng';
      
      // Step 2: Update Planning API - sama seperti flow manual
      print('=== STEP 2: UPDATE PLANNING ===');
      print('Calling updatePlanning with: idTool=$idToolInt, cashierCode=$currentUser, spvTLCode=$cleanNik, tableCode=$tableCode');
      
      final planningResponse = await _apiService.updatePlanning(
        idTool: idToolInt,
        cashierCode: currentUser,
        spvTLCode: cleanNik,
        tableCode: tableCode,
        warehouseCode: warehouseCode,
      );
      
      if (!planningResponse.success) {
        throw Exception('Update planning gagal: ${planningResponse.message}');
      }
      
      print('Planning update success for ID: $idTool by TL: $cleanNik ($currentUserName)');
      
      // Kirim notifikasi ke CRF_OPR jika ada informasi operator
      if (_operatorId != null && _operatorId!.isNotEmpty) {
        try {
          await _notificationService.sendNotification(
            idTool: idTool,
            action: 'PREPARE_APPROVED',
            status: 'SUCCESS',
            message: 'Prepare dengan ID: $idTool telah berhasil diapprove oleh TL: $currentUserName',
            fromUser: currentUser,
            toUser: _operatorId!,
            additionalData: null,
          );
          
          print('Notification sent to CRF_OPR: ${_operatorId}');
        } catch (e) {
          print('Error sending notification: $e');
        }
      }
    } catch (e) {
      print('Error approving prepare: $e');
      throw Exception('Approval gagal: ${e.toString()}');
    }
  }

  Future<void> _approveReturn(String idTool, String tlNik, String tlName, bool bypassNikValidation, String? tlspvPassword) async {
    try {
      print('Approving return for ID: $idTool by TL: $tlNik ($tlName), bypassValidation: $bypassNikValidation, hasPassword: ${tlspvPassword != null}');
      
      // PERBAIKAN: Gunakan kredensial login CRF_TL, bukan dari QR
      final userData = await _authService.getUserData();
      final currentUser = userData?['nik'] ?? userData?['userID'] ?? 'UNKNOWN';
      final currentUserName = userData?['userName'] ?? '';
      
      // Dapatkan kredensial TL dari data login, bukan dari QR
      final tlCredentials = await _authService.getTLSPVCredentials();
      
      if (tlCredentials == null || 
          !tlCredentials.containsKey('username') || 
          !tlCredentials.containsKey('password') ||
          tlCredentials['username'] == null ||
          tlCredentials['password'] == null) {
        throw Exception('Kredensial TL tidak tersedia. Silakan login kembali.');
      }
      
      final tlNikFromLogin = tlCredentials['username'].toString();
      final tlPasswordFromLogin = tlCredentials['password'].toString();
      
      print('Using TL credentials from login: $tlNikFromLogin');
      
      // Validasi nilai NIK
      if (tlNikFromLogin.isEmpty) {
        throw Exception('NIK TL tidak boleh kosong');
      }
      
      // Pastikan NIK dan password bersih dari whitespace
      final cleanNik = tlNikFromLogin.trim();
      final cleanPassword = tlPasswordFromLogin.trim();
      
      // Step 1: Validasi TL Supervisor credentials dan role - sama seperti flow manual
      print('=== STEP 1: VALIDATE TL SUPERVISOR ===');
      final validationResponse = await _apiService.validateTLSupervisor(
        nik: cleanNik,
        password: cleanPassword
      );
        
      if (!validationResponse.success || validationResponse.data?.validationStatus != 'SUCCESS') {
        throw Exception('Validasi TLSPV gagal: ${validationResponse.message}');
      }
        
      print('TLSPV validation successful: ${validationResponse.data?.userName} (${validationResponse.data?.userRole})');
      
      // Pastikan idTool valid
      String cleanIdTool = idTool.trim();
      
      // Dapatkan data user saat ini untuk parameter tambahan
      final tableCode = userData?['tableCode'] ?? 'DEFAULT';
      final warehouseCode = userData?['warehouseCode'] ?? 'Cideng';
      
      // Step 2: Update Planning RTN - sama seperti flow manual
      print('=== STEP 2: UPDATE PLANNING RTN ===');
      final updateParams = {
        "idTool": cleanIdTool,
        "CashierReturnCode": currentUser,
        "TableReturnCode": tableCode,
        "DateStartReturn": DateTime.now().toIso8601String(),
        "WarehouseCode": warehouseCode,
        "UserATMReturn": cleanNik,
        "SPVBARusak": cleanNik,
        "IsManual": "N"
      };
      
      final updateResponse = await _apiService.updatePlanningRTN(updateParams);
      
      if (!updateResponse.success) {
        throw Exception('Update planning RTN gagal: ${updateResponse.message}');
      }
      
      print('Return approved for ID: $idTool by TL: $cleanNik ($currentUserName)');
      
      // Kirim notifikasi ke CRF_OPR jika ada informasi operator
      if (_operatorId != null && _operatorId!.isNotEmpty) {
        try {
          await _notificationService.sendNotification(
            idTool: idTool,
            action: 'RETURN_APPROVED',
            status: 'SUCCESS',
            message: 'Return dengan ID: $idTool telah berhasil diapprove oleh TL: $currentUserName',
            fromUser: currentUser,
            toUser: _operatorId!,
            additionalData: null,
          );
          
          print('Notification sent to CRF_OPR: ${_operatorId}');
        } catch (e) {
          print('Error sending notification: $e');
        }
      }
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
  
  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
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
            child: SingleChildScrollView(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Kredensial TL form card
                Card(
                    elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                  ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          const Text(
                            'Simpan Kredensial TL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Simpan kredensial TL untuk digunakan dalam QR code',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _nikController,
                            decoration: const InputDecoration(
                              labelText: 'NIK TL',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSavingCredentials ? null : _saveCredentials,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isSavingCredentials
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                : const Text('Simpan Kredensial'),
                            ),
                          ),
                        ],
                    ),
                  ),
                ),
                
                  const SizedBox(height: 20),
                  
                  // Existing content
                  Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                            'Scan QR Code',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _openQRScanner,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Scan QR Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0056A4),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              ),
                            ),
                          ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Recent scans
                  if (_recentScans.isNotEmpty) ...[
                    const Text(
                      'Riwayat Scan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._recentScans.map((scan) => _buildScanHistoryItem(scan)),
                  ],
                ],
              ),
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

  Widget _buildScanHistoryItem(Map<String, dynamic> scan) {
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
} 
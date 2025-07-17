import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add clipboard import
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/return_model.dart';
import 'dart:async'; // Import for Timer
import '../widgets/barcode_scanner_widget.dart'; // Fix barcode scanner import

// CHECKMARK FIX: This file has been updated to fix the checkmark display issue.
// Changes made:
// 1. Modified barcode scanning to handle results in parent methods instead of callbacks
// 2. Added setState() calls to update UI after scanning
// 3. Enhanced checkmark visibility in the UI
// 4. Added debug logging to track scan states

void main() {
  runApp(const ReturnModeApp());
}

class ReturnModeApp extends StatelessWidget {
  const ReturnModeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Return Mode',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ReturnModePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ReturnModePage extends StatefulWidget {
  const ReturnModePage({Key? key}) : super(key: key);

  @override
  State<ReturnModePage> createState() => _ReturnModePageState();
}

class _ReturnModePageState extends State<ReturnModePage> {
  final TextEditingController _idCRFController = TextEditingController();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  String _branchCode = '';
  String _errorMessage = '';
  bool _isLoading = false;
  // State untuk data return dan detail header
  ReturnHeaderResponse? _returnHeaderResponse;
  Map<String, dynamic>? _userData;

  // References to cartridge sections - now using a list to handle dynamic sections
  final List<GlobalKey<_CartridgeSectionState>> _cartridgeSectionKeys = [];
  
  // New ID Tool controller for all sections
  final TextEditingController _idToolController = TextEditingController();
  
  // Add jamMulai controller
  final TextEditingController _jamMulaiController = TextEditingController();
  
  // Timer for debouncing ID Tool typing
  Timer? _idToolTypingTimer;
  
  // TL approval controllers
  final TextEditingController _tlNikController = TextEditingController();
  final TextEditingController _tlPasswordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _idCRFController.dispose();
    _tlNikController.dispose();
    _tlPasswordController.dispose();
    _idToolController.dispose(); // Dispose the new ID Tool controller
    _jamMulaiController.dispose(); // Dispose jamMulai controller
    if (_idToolTypingTimer != null) {
      _idToolTypingTimer!.cancel();
    }
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      setState(() {
        if (userData != null) {
          _userData = userData;
          
          // First try to get branchCode directly
          if (userData.containsKey('branchCode') && userData['branchCode'] != null && userData['branchCode'].toString().isNotEmpty) {
            _branchCode = userData['branchCode'].toString();
            print('Using branchCode from userData: $_branchCode');
          } 
          // Then try groupId as fallback
          else if (userData.containsKey('groupId') && userData['groupId'] != null && userData['groupId'].toString().isNotEmpty) {
            _branchCode = userData['groupId'].toString();
            print('Using groupId as branchCode: $_branchCode');
          }
          // Finally try BranchCode (different casing)
          else if (userData.containsKey('BranchCode') && userData['BranchCode'] != null && userData['BranchCode'].toString().isNotEmpty) {
            _branchCode = userData['BranchCode'].toString();
            print('Using BranchCode from userData: $_branchCode');
          }
          // Default to '1' if nothing found
          else {
            _branchCode = '1';
            print('No branch code found in userData, using default: $_branchCode');
          }
          
          // Print all user data for debugging
          print('User data: $userData');
        } else {
          _branchCode = '1';
          print('No user data found, using default branch code: $_branchCode');
        }
      });
    } catch (e) {
      setState(() {
        _branchCode = '1';
        print('Error loading user data: $e, using default branch code: $_branchCode');
      });
    }
  }

  Future<void> _fetchReturnData() async {
    final idCrf = _idCRFController.text.trim();
    if (idCrf.isEmpty) {
      _showErrorDialog('ID CRF tidak boleh kosong');
      return;
    }
    
    setState(() { 
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Debug: Print state before fetch
      print('Fetching return data for ID CRF: $idCrf');
      
      final response = await _apiService.getReturnHeaderAndCatridge(idCrf, branchCode: _branchCode);
      
      setState(() {
        if (response.success) {
          _returnHeaderResponse = response;
          _errorMessage = '';
          
          // Set jamMulai with current time
          final now = DateTime.now();
          _jamMulaiController.text = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
          
          // Create the cartridge section keys based on the response
          _cartridgeSectionKeys.clear();
          if (response.data.isNotEmpty) {
            for (int i = 0; i < response.data.length; i++) {
              _cartridgeSectionKeys.add(GlobalKey<_CartridgeSectionState>());
            }
            
            // For debugging
            print('Created ${_cartridgeSectionKeys.length} cartridge section keys for ${response.data.length} catridges');
            for (int i = 0; i < response.data.length; i++) {
              print('Catridge ${i+1}: Code=${response.data[i].catridgeCode}, Type=${response.data[i].typeCatridge}, TypeTrx=${response.data[i].typeCatridgeTrx ?? "C"}');
            }
          }
        } else {
          _showErrorDialog(response.message);
        }
      });
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // If error is about serah terima, maybe provide a button to go to CPC
              if (message.contains('serah terima')) {
                // TODO: Navigate to CPC menu or show instructions
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sukses'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openBarcodeScanner() async {
    // TODO: Implementasi scan barcode dan set _idCRFController.text
  }

  // Check if all forms are valid
  bool get _isFormsValid {
    if (_cartridgeSectionKeys.isEmpty) return false;
    
    // Check all cartridge sections
    for (var key in _cartridgeSectionKeys) {
      if (!(key.currentState?.isFormValid ?? false)) {
        return false;
      }
    }
    
    return true;
  }

  // Show TL approval dialog
  Future<void> _showTLApprovalDialog() async {
    if (!_isFormsValid) {
      _showErrorDialog('Harap lengkapi semua field dengan benar sebelum submit');
      return;
    }
    
    _tlNikController.clear();
    _tlPasswordController.clear();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approval Team Leader'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Masukkan NIK dan Password Team Leader untuk approval:'),
                const SizedBox(height: 16),
                TextField(
                  controller: _tlNikController,
                  decoration: const InputDecoration(
                    labelText: 'NIK TL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tlPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            _isSubmitting
                ? const CircularProgressIndicator()
                : TextButton(
                    child: const Text('Approve'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _validateTLAndSubmit();
                    },
                  ),
          ],
        );
      },
    );
  }

  // Validate TL credentials and submit data
  Future<void> _validateTLAndSubmit() async {
    if (_tlNikController.text.isEmpty || _tlPasswordController.text.isEmpty) {
      _showErrorDialog('NIK dan Password TL harus diisi');
      return;
    }
    
    setState(() { _isSubmitting = true; });
    
    try {
      // Validate TL credentials
      final tlResponse = await _apiService.validateTLSupervisor(
        nik: _tlNikController.text,
        password: _tlPasswordController.text,
      );
      
      if (!tlResponse.success) {
        _showErrorDialog(tlResponse.message);
        setState(() { _isSubmitting = false; });
        return;
      }
      
      // 1. Update Planning RTN first - this is crucial for correct flow
      print('Updating Planning RTN...');
      final updateParams = {
        "idTool": _idToolController.text,
        "CashierReturnCode": _userData?['nik'] ?? '',
        "TableReturnCode": _userData?['tableCode'] ?? '',
        "DateStartReturn": DateTime.now().toIso8601String(),
        "WarehouseCode": _userData?['warehouseCode'] ?? 'Cideng',
        "UserATMReturn": _tlNikController.text,
        "SPVBARusak": _tlNikController.text,
        "IsManual": "N"
      };
      
      final updateResponse = await _apiService.updatePlanningRTN(updateParams);
      
      if (!updateResponse.success) {
        _showErrorDialog('Gagal update planning RTN: ${updateResponse.message}');
        setState(() { _isSubmitting = false; });
        return;
      }
      
      print('Planning RTN updated successfully!');
      
      // 2. Now insert each catridge data into RTN
      if (_returnHeaderResponse?.data == null || _returnHeaderResponse!.data.isEmpty) {
        _showErrorDialog('Tidak ada data catridge untuk diproses');
        setState(() { _isSubmitting = false; });
        return;
      }
      
      bool allSuccess = true;
      String errorMessage = '';
      
      // Process each catridge
      for (int i = 0; i < _returnHeaderResponse!.data.length; i++) {
        final catridge = _returnHeaderResponse!.data[i];
        
        print('Processing catridge ${i+1} of ${_returnHeaderResponse!.data.length}: ${catridge.catridgeCode}');
        
        // Send to RTN endpoint
        final rtneResponse = await _apiService.insertReturnAtmCatridge(
          idTool: _idToolController.text,
          bagCode: catridge.bagCode ?? '0',
          catridgeCode: catridge.catridgeCode,
          sealCode: '0', // Use default or get from catridge data if available
          catridgeSeal: catridge.catridgeSeal,
          denomCode: catridge.denomCode,
          qty: catridge.qty ?? '0',
          userInput: _userData?['nik'] ?? '',
          isBalikKaset: "N",
          scanCatStatus: "TEST", 
          scanCatStatusRemark: "Processed from mobile app",
          scanSealStatus: "TEST",
          scanSealStatusRemark: "Processed from mobile app"
        );
        
        if (!rtneResponse.success) {
          allSuccess = false;
          errorMessage = rtneResponse.message;
          print('Failed to insert catridge ${catridge.catridgeCode}: ${rtneResponse.message}');
          break;
        }
        
        print('Successfully inserted catridge ${catridge.catridgeCode}');
      }
      
      setState(() { _isSubmitting = false; });
      
      if (allSuccess) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Berhasil'),
              content: const Text('Data return berhasil disimpan'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Return to home page
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        _showErrorDialog('Gagal menyimpan data return: $errorMessage');
      }
    } catch (e) {
      setState(() { _isSubmitting = false; });
      _showErrorDialog('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<void> _submitReturnData() async {
    if (_returnHeaderResponse == null || _returnHeaderResponse!.data.isEmpty) {
      setState(() { _errorMessage = 'Tidak ada data untuk disubmit'; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });
    
    try {
      // Check if we have any cartridge sections
      if (_cartridgeSectionKeys.isEmpty) {
        throw Exception('Tidak ada data catridge untuk disubmit');
      }
      
      bool allSuccess = true;
      
      // Submit data for each cartridge section
      for (int i = 0; i < _cartridgeSectionKeys.length; i++) {
        if (i >= _returnHeaderResponse!.data.length) break;
        
        final catridgeState = _cartridgeSectionKeys[i].currentState!;
        
        final response = await _apiService.insertReturnAtmCatridge(
          idTool: _idToolController.text,
          bagCode: catridgeState.bagCode ?? '',
          catridgeCode: catridgeState.noCatridgeController.text,
          sealCode: catridgeState.sealCode ?? '',
          catridgeSeal: catridgeState.noSealController.text,
          denomCode: _returnHeaderResponse!.data[i].denomCode,
          qty: '0',
          userInput: _userData?['nik'] ?? '',
          isBalikKaset: 'N',
          scanCatStatus: catridgeState.kondisiCatridge ?? 'New',
          scanCatStatusRemark: '',
          scanSealStatus: catridgeState.kondisiSeal ?? 'Good',
          scanSealStatusRemark: '',
        );
        
        if (!response.success) {
          allSuccess = false;
          throw Exception(response.message);
        }
      }
      
      // Tampilkan dialog sukses
      _showSuccessDialog('Data return berhasil disubmit');
      
      // Reset form
      _idCRFController.clear();
      _idToolController.clear();
      setState(() {
        _returnHeaderResponse = null;
      });
      
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
      _showErrorDialog('Error submit data: ${e.toString()}');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // New method to fetch data directly using ID Tool
  Future<void> _fetchDataByIdTool(String idTool) async {
    if (idTool.isEmpty) {
      _showErrorDialog('ID Tool tidak boleh kosong');
      return;
    }
    
    setState(() { 
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Ensure branchCode is numeric
      String numericBranchCode = _branchCode;
      if (_branchCode.isEmpty || !RegExp(r'^\d+$').hasMatch(_branchCode)) {
        numericBranchCode = '1'; // Default to '1' if not numeric
        print('WARNING: Branch code is not numeric: "$_branchCode", using default: $numericBranchCode');
      }
      
      // Debug: Print state before fetch
      print('Direct API Call: Fetching data for ID Tool: $idTool with branchCode: $numericBranchCode');
      
      // Call the raw API method for direct control
      final rawResponse = await _apiService.validateAndGetReplenishRaw(idTool, numericBranchCode);
      
      // Debug: Print full response for analysis
      print('API Response: $rawResponse');
      
      setState(() {
        if (rawResponse['success'] == true && rawResponse['data'] != null) {
          
          // Create artificial ReturnHeaderResponse from raw data
          final data = rawResponse['data'];
          
          // Create ReturnHeaderData from raw data
          final header = ReturnHeaderData(
            atmCode: data['atmCode'] ?? '',
            namaBank: data['namaBank'] ?? 'Not Available',
            lokasi: data['lokasi'] ?? 'Not Available',
            typeATM: data['typeATM'] ?? 'Not Available',
          );
          
          // Extract catridges array
          final catridgesArray = data['catridges'] as List<dynamic>? ?? [];
          print('Catridges array length: ${catridgesArray.length}');
          
          // Convert each catridge to ReturnCatridgeData
          List<ReturnCatridgeData> catridgesList = [];
          for (var catridge in catridgesArray) {
            print('Processing catridge: $catridge');
            final typeCatridgeTrx = catridge['typeCatridgeTrx'] ?? 'C';
            print('TypeCatridgeTrx: $typeCatridgeTrx');
            
            final returnCatridgeData = ReturnCatridgeData(
              idTool: idTool,
              catridgeCode: catridge['catridgeCode'] ?? '',
              catridgeSeal: catridge['catridgeSeal'] ?? '',
              denomCode: '100K', // Default since API doesn't provide it
              typeCatridge: catridge['dataType'] ?? 'REPLENISH_DATA',
              bagCode: catridge['bagCode'] ?? '',
              qty: '0',
              typeCatridgeTrx: typeCatridgeTrx,
              sealCodeReturn: catridge['sealCodeReturn'] ?? '',
            );
            
            catridgesList.add(returnCatridgeData);
          }
          
          // Create ReturnHeaderResponse
          _returnHeaderResponse = ReturnHeaderResponse(
            success: true,
            message: rawResponse['message'] ?? 'Data retrieved successfully',
            header: header,
            data: catridgesList,
          );
          
          // Debugging
          print('Created ReturnHeaderResponse with ${catridgesList.length} catridges');
          
          // Create cartridge section keys based on the catridges
          _cartridgeSectionKeys.clear();
          for (int i = 0; i < catridgesList.length; i++) {
            _cartridgeSectionKeys.add(GlobalKey<_CartridgeSectionState>());
            print('Added key for catridge ${i+1}');
          }
          
          // Reset scan status for all sections
          Future.delayed(Duration.zero, () {
            for (var key in _cartridgeSectionKeys) {
              if (key.currentState != null) {
                key.currentState!.setState(() {
                  // Reset all scan validation flags
                  key.currentState!.scannedFields.forEach((fieldKey, value) {
                    key.currentState!.scannedFields[fieldKey] = false;
                  });
                });
              }
            }
          });
          
          _errorMessage = '';
        } else {
          _errorMessage = rawResponse['message'] ?? 'Failed to retrieve data';
          _showErrorDialog(_errorMessage);
        }
      });
    } catch (e) {
      _showErrorDialog('Error fetching data: ${e.toString()}');
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // Method to scan ID Tool
  Future<void> _scanIdTool() async {
    try {
      // Navigate to barcode scanner
      final result = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeScannerWidget(
            title: 'Scan ID Tool',
            forceShowCheckmark: false, // FIX: Let scanner close itself
            onBarcodeDetected: (String barcode) {
              Navigator.of(context).pop(barcode);
            },
          ),
        ),
      );
      
      // If no barcode was scanned (user cancelled), return early
      if (result == null) {
        print('ID Tool scanning cancelled');
        return;
      }
      
      String barcode = result;
      print('ID Tool scanned: $barcode');
      
      setState(() {
        _idToolController.text = barcode;
      });
      
      // Reset all scan validation states in all cartridge sections
      for (var key in _cartridgeSectionKeys) {
        if (key.currentState != null) {
          key.currentState!.setState(() {
            // Reset the scannedFields map for each section
            key.currentState!.scannedFields.forEach((fieldKey, value) {
              key.currentState!.scannedFields[fieldKey] = false;
            });
            
            // Force a rebuild to update the UI
            key.currentState!.setState(() {});
          });
        }
      }
      
      // Fetch data using the scanned ID Tool
      _fetchDataByIdTool(barcode);
    } catch (e) {
      print('Error opening barcode scanner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka scanner: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTabletOrLandscapeMobile = size.width >= 600;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 60,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {},
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 8),
              const Text(
                'Return Mode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _userData?['branchName'] ?? 'JAKARTA-CIDENG',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Meja : ${_userData?['tableCode'] ?? '010101'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CRF_OPR',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.refresh, color: Colors.green),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                        'https://randomuser.me/api/portraits/men/75.jpg'),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _userData?['name'] ?? 'Lorenzo Putra',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        _userData?['nik'] ?? '9190812021',
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Loading indicator
          if (_isLoading)
            const LinearProgressIndicator(),
            
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              // Use LayoutBuilder to handle responsive layout
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use Row for wide screens, Column for narrow screens
                  final useRow = constraints.maxWidth >= 600;
                  
                  // Create dynamic cartridge sections based on API response
                  List<Widget> cartridgeSections = [];
                  
                  // Clear and recreate keys when response changes
                  if (_returnHeaderResponse?.data != null && _cartridgeSectionKeys.length != _returnHeaderResponse!.data.length) {
                    _cartridgeSectionKeys.clear();
                    for (int i = 0; i < _returnHeaderResponse!.data.length; i++) {
                      _cartridgeSectionKeys.add(GlobalKey<_CartridgeSectionState>());
                      print('Created key for item ${i+1} of ${_returnHeaderResponse!.data.length}');
                    }
                  }
                  
                  // Build cartridge sections based on response data
                  if (_returnHeaderResponse?.data != null) {
                    print('Building ${_returnHeaderResponse!.data.length} cartridge sections');
                    print('Current keys: ${_cartridgeSectionKeys.length}');
                    
                    // Ensure we have the right number of keys
                    if (_cartridgeSectionKeys.length != _returnHeaderResponse!.data.length) {
                      _cartridgeSectionKeys.clear();
                      for (int i = 0; i < _returnHeaderResponse!.data.length; i++) {
                        _cartridgeSectionKeys.add(GlobalKey<_CartridgeSectionState>());
                        print('Created key for item ${i+1} of ${_returnHeaderResponse!.data.length}');
                      }
                    }
                    
                    for (int i = 0; i < _returnHeaderResponse!.data.length; i++) {
                      if (i < _cartridgeSectionKeys.length) { // Safety check
                        final data = _returnHeaderResponse!.data[i];
                        
                        // Debug the data
                        print('Data at index $i: id=${data.idTool}, code=${data.catridgeCode}, typeTrx=${data.typeCatridgeTrx}');
                        
                        // Determine section title based on typeCatridgeTrx
                        String sectionTitle;
                        final typeCatridgeTrx = data.typeCatridgeTrx?.toUpperCase() ?? 'C';
                        
                        switch (typeCatridgeTrx) {
                          case 'C':
                            sectionTitle = 'Catridge ${i + 1}';
                            break;
                          case 'D':
                            sectionTitle = 'Divert ${i + 1}';
                            break;
                          case 'P':
                            sectionTitle = 'Pocket ${i + 1}';
                            break;
                          default:
                            sectionTitle = 'Catridge ${i + 1}';
                        }
                        
                        print('Adding section: $sectionTitle for index $i');
                        
                        cartridgeSections.add(
                          Column(
                            children: [
                              CartridgeSection(
                                key: _cartridgeSectionKeys[i],
                                title: sectionTitle,
                                returnData: data,
                                parentIdToolController: _idToolController,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      }
                    }
                  } else {
                    // Add at least one empty cartridge section if no data
                    _cartridgeSectionKeys.clear();
                    _cartridgeSectionKeys.add(GlobalKey<_CartridgeSectionState>());
                    
                    cartridgeSections.add(
                      Column(
                        children: [
                          CartridgeSection(
                            key: _cartridgeSectionKeys[0],
                            title: 'Catridge 1',
                            returnData: null,
                            parentIdToolController: _idToolController,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  }

                  // Build the main content
                  Widget mainContent;
                  
                  // ID Tool and Jam Mulai fields
                  Widget idToolAndJamMulaiFields = Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ID Tool field - reduced width (1/4 of screen)
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 80,
                                child: Text(
                                  'ID Tool:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _idToolController,
                                  decoration: const InputDecoration(
                                    hintText: 'Masukkan ID Tool',
                                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    // Debounce typing
                                    if (_idToolTypingTimer != null) {
                                      _idToolTypingTimer!.cancel();
                                    }
                                    _idToolTypingTimer = Timer(const Duration(milliseconds: 500), () {
                                      // Use the direct method to fetch data by ID Tool
                                      if (value.isNotEmpty) {
                                        _fetchDataByIdTool(value);
                                      }
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                                onPressed: () {
                                  // Open barcode scanner for ID Tool
                                  _scanIdTool();
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Jam Mulai field
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 80,
                                child: Text(
                                  'Jam Mulai:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: TextFormField(
                                  controller: _jamMulaiController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    hintText: '--:--',
                                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.access_time, color: Colors.grey),
                                onPressed: null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (useRow) {
                    // Row layout for tablets and desktop
                    mainContent = Column(
                      children: [
                        idToolAndJamMulaiFields,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: cartridgeSections,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 4,
                              child: DetailSection(
                                returnData: _returnHeaderResponse,
                                onSubmitPressed: _showTLApprovalDialog,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Column layout for phones
                    mainContent = Column(
                      children: [
                        idToolAndJamMulaiFields,
                        ...cartridgeSections,
                        DetailSection(
                          returnData: _returnHeaderResponse,
                          onSubmitPressed: _showTLApprovalDialog,
                        ),
                      ],
                    );
                  }
                  
                  return mainContent;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CartridgeSection extends StatefulWidget {
  final String title;
  final ReturnCatridgeData? returnData;
  final TextEditingController parentIdToolController;
  
  const CartridgeSection({
    Key? key, 
    required this.title, 
    this.returnData,
    required this.parentIdToolController,
  }) : super(key: key);

  @override
  State<CartridgeSection> createState() => _CartridgeSectionState();
}

class _CartridgeSectionState extends State<CartridgeSection> {
  String? kondisiSeal;
  String? kondisiCatridge;
  String wsidValue = '';

  // Modified to only have two options
  final List<String> kondisiSealOptions = ['Good', 'Bad'];
  final List<String> kondisiCatridgeOptions = ['New', 'Used'];

  final TextEditingController noCatridgeController = TextEditingController();
  final TextEditingController noSealController = TextEditingController();
  final TextEditingController catridgeFisikController = TextEditingController();
  final TextEditingController bagCodeController = TextEditingController();
  final TextEditingController sealCodeReturnController = TextEditingController();
  final TextEditingController branchCodeController = TextEditingController();

  // Add getters for bagCode and sealCode
  String? get bagCode => bagCodeController.text;
  String? get sealCode => sealCodeReturnController.text;
  
  // Add numericBranchCode getter to fix the error
  String get numericBranchCode {
    // Ensure branchCode is numeric
    if (branchCodeController.text.isEmpty || !RegExp(r'^\d+$').hasMatch(branchCodeController.text)) {
      return '1'; // Default to '1' if not numeric
    }
    return branchCodeController.text;
  }
  
  // Add a method to force rebuild the UI
  void _forceRebuild() {
    if (mounted) {
      setState(() {
        // Force a complete UI rebuild to ensure checkmarks display properly
      });
    }
  }

  // NEW APPROACH: Use a map to track which fields have been scanned
  Map<String, bool> scannedFields = {
    'noCatridge': false,
    'noSeal': false,
    'catridgeFisik': false,
    'bagCode': false,
    'sealCode': false,
  };

  final Map<String, TextEditingController> denomControllers = {
    '100K': TextEditingController(),
    '75K': TextEditingController(),
    '50K': TextEditingController(),
    '20K': TextEditingController(),
    '10K': TextEditingController(),
    '5K': TextEditingController(),
    '2K': TextEditingController(),
    '1K': TextEditingController(),
  };

  // Validation state
  bool isNoCatridgeValid = true;
  bool isNoSealValid = true;
  bool isCatridgeFisikValid = true;
  bool isKondisiSealValid = true;
  bool isKondisiCatridgeValid = true;
  bool isBagCodeValid = true;
  bool isSealCodeReturnValid = true;
  bool isDenomValid = true;

  // Error messages
  String noCatridgeError = '';
  String noSealError = '';
  String catridgeFisikError = '';
  String kondisiSealError = '';
  String kondisiCatridgeError = '';
  String bagCodeError = '';
  String sealCodeReturnError = '';
  String denomError = '';

  // API service
  final ApiService _apiService = ApiService();
  bool _isValidating = false;
  bool _isLoading = false;
  
  // Data baru
  String _branchCode = '1'; // Default branch code

  @override
  void initState() {
    super.initState();
    _loadReturnData();
    _loadUserData();
    
    // Set default branch code
    branchCodeController.text = _branchCode;
    
    // Initialize scannedFields map
    scannedFields = {
      'noCatridge': false,
      'noSeal': false,
      'catridgeFisik': false,
      'bagCode': false,
      'sealCode': false,
    };
    
    // Debug log
    print('INIT: scannedFields initialized: $scannedFields');
  }

  @override
  void dispose() {
    noCatridgeController.dispose();
    noSealController.dispose();
    catridgeFisikController.dispose();
    bagCodeController.dispose();
    sealCodeReturnController.dispose();
    branchCodeController.dispose();
    for (var c in denomControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
  
  // Load user data untuk mendapatkan branch code
  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();
      final userData = await authService.getUserData();
      if (userData != null) {
        setState(() {
          // First try to get branchCode directly
          if (userData.containsKey('branchCode') && userData['branchCode'] != null && userData['branchCode'].toString().isNotEmpty) {
            _branchCode = userData['branchCode'].toString();
            print('CartridgeSection: Using branchCode from userData: $_branchCode');
          } 
          // Then try groupId as fallback
          else if (userData.containsKey('groupId') && userData['groupId'] != null && userData['groupId'].toString().isNotEmpty) {
            _branchCode = userData['groupId'].toString();
            print('CartridgeSection: Using groupId as branchCode: $_branchCode');
          }
          // Finally try BranchCode (different casing)
          else if (userData.containsKey('BranchCode') && userData['BranchCode'] != null && userData['BranchCode'].toString().isNotEmpty) {
            _branchCode = userData['BranchCode'].toString();
            print('CartridgeSection: Using BranchCode from userData: $_branchCode');
          }
          // Default to '1' if nothing found
          else {
            _branchCode = '1';
            print('CartridgeSection: No branch code found in userData, using default: $_branchCode');
          }
          
          branchCodeController.text = _branchCode;
        });
      }
    } catch (e) {
      print('CartridgeSection: Error loading user data: $e, using default branch code: 1');
      setState(() {
        _branchCode = '1';
        branchCodeController.text = _branchCode;
      });
    }
  }
  
  // New method to fetch data from API with provided idTool
  Future<void> fetchDataFromApi(String idTool) async {
    if (idTool.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan ID Tool terlebih dahulu'))
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      
      // Reset all scanned fields flags
      scannedFields.forEach((key, value) {
        scannedFields[key] = false;
      });
    });
    
    try {
      // Ensure branchCode is numeric
      String numericBranchCode = branchCodeController.text;
      if (branchCodeController.text.isEmpty || !RegExp(r'^\d+$').hasMatch(branchCodeController.text)) {
        numericBranchCode = '1'; // Default to '1' if not numeric
        print('WARNING: Branch code is not numeric: "${branchCodeController.text}", using default: $numericBranchCode');
        branchCodeController.text = numericBranchCode;
      }
      
      // Log the request for debugging
      print('Fetching data with idTool: $idTool, branchCode: $numericBranchCode (original: ${branchCodeController.text})');
      
      // Create test URL for manual verification
      final String testUrl = 'http://10.10.0.223/LocalCRF/api/CRF/rtn/validate-and-get-replenish?idtool=$idTool&branchCode=$numericBranchCode';
      print('Test URL: $testUrl');
      
      final result = await _apiService.validateAndGetReplenishRaw(
        idTool,
        numericBranchCode,
        catridgeCode: noCatridgeController.text.isNotEmpty ? noCatridgeController.text : null,
      );
      
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          // Set WSID from atmCode
          if (result['data']['atmCode'] != null) {
            wsidValue = result['data']['atmCode'].toString();
          }
          
          // Process catridge data if available
          if (result['data']['catridges'] != null && result['data']['catridges'] is List && (result['data']['catridges'] as List).isNotEmpty) {
            final catridgeData = (result['data']['catridges'] as List).first;
            
            // Fill fields from API data
            if (catridgeData['catridgeCode'] != null || catridgeData['CatridgeCode'] != null) {
              noCatridgeController.text = catridgeData['catridgeCode'] ?? catridgeData['CatridgeCode'] ?? '';
            }
            
            if (catridgeData['catridgeSeal'] != null || catridgeData['CatridgeSeal'] != null) {
              noSealController.text = catridgeData['catridgeSeal'] ?? catridgeData['CatridgeSeal'] ?? '';
            }
            
            if (catridgeData['bagCode'] != null) {
              bagCodeController.text = catridgeData['bagCode'] ?? '';
            }
            
            if (catridgeData['sealCodeReturn'] != null) {
              sealCodeReturnController.text = catridgeData['sealCodeReturn'] ?? '';
            }
            
            // Set validation flags
            isNoCatridgeValid = noCatridgeController.text.isNotEmpty;
            isNoSealValid = noSealController.text.isNotEmpty;
            isBagCodeValid = true;
            isSealCodeReturnValid = true;
            
            // IMPORTANT: Reset all scanned fields flags
            scannedFields.forEach((key, value) {
              scannedFields[key] = false;
            });
            
            print('Scan states reset after API fetch:');
            print('Scanned fields: $scannedFields');
          } else {
            print('No catridges data found in response or empty list');
          }
        });
      } else {
        // Enhanced error handling
        String errorMessage = result['message'] ?? 'Gagal mengambil data';
        
        // Add debugging info for 404 errors
        if (errorMessage.contains('404')) {
          errorMessage += '\n\nDetail permintaan:\nURL: 10.10.0.223/LocalCRF/api/CRF/rtn/validate-and-get-replenish'
              '\nParameter: idtool=$idTool, branchCode=$numericBranchCode';
              
          print('404 Error: $errorMessage');
          
          // Show more detailed error message with test URL
          _showDetailedErrorDialog(
            title: 'Kesalahan API (404)',
            message: 'Endpoint API tidak ditemukan. Mohon periksa konfigurasi server atau parameter.',
            technicalDetails: errorMessage,
            testUrl: testUrl
          );
        } else {
          // Show more detailed error message for other errors
          _showDetailedErrorDialog(
            title: 'Kesalahan API',
            message: errorMessage,
            technicalDetails: 'Endpoint: /CRF/rtn/validate-and-get-replenish\n'
                'ID Tool: $idTool\n'
                'Branch Code: $numericBranchCode',
            testUrl: testUrl
          );
        }
      }
    } catch (e) {
      // Enhanced error dialog with technical details
      _showDetailedErrorDialog(
        title: 'Kesalahan Jaringan',
        message: 'Terjadi kesalahan saat menghubungi server. Mohon periksa koneksi internet dan coba lagi.',
        technicalDetails: e.toString(),
        testUrl: 'http://10.10.0.223/LocalCRF/api/CRF/rtn/validate-and-get-replenish?idtool=${widget.parentIdToolController.text}&branchCode=$numericBranchCode'
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Modified _fetchDataFromApi to use the parent ID Tool
  Future<void> _fetchDataFromApi() async {
    await fetchDataFromApi(widget.parentIdToolController.text);
  }

  // Helper method to show detailed error dialog with technical info
  void _showDetailedErrorDialog({
    required String title, 
    required String message,
    String? technicalDetails,
    String? testUrl
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (technicalDetails != null) ...[
                const SizedBox(height: 16),
                const Text('Informasi Teknis:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    technicalDetails,
                    style: TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.grey[800]),
                  ),
                ),
              ],
              if (testUrl != null && testUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'URL yang dapat diuji secara manual:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    testUrl,
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
          if (technicalDetails != null)
            TextButton(
              onPressed: () {
                // Copy technical details to clipboard
                Clipboard.setData(ClipboardData(text: technicalDetails));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informasi teknis disalin ke clipboard'))
                );
              },
              child: const Text('Salin Info Teknis'),
            ),
          if (testUrl != null && testUrl.isNotEmpty)
            TextButton(
              onPressed: () {
                // Would normally launch URL but requires url_launcher package
                // Instead we'll copy it to clipboard
                Clipboard.setData(ClipboardData(text: testUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL disalin ke clipboard, buka di browser untuk menguji API secara langsung'))
                );
              },
              child: const Text('Salin URL Test'),
            ),
        ],
      ),
    );
  }

  Future<void> _validateNoCatridge() async {
    setState(() {
      _isValidating = true;
      noCatridgeError = ''; // Reset error message
    });
    
    // Get the catridge code
    final catridgeCode = noCatridgeController.text;
    
    // Basic validation - ensure it's not empty
    if (catridgeCode.isEmpty) {
      setState(() {
        isNoCatridgeValid = false;
        noCatridgeError = 'Nomor Catridge tidak boleh kosong';
        _isValidating = false;
      });
      return;
    }
    
    // Try to fetch data from API if ID Tool is filled
    if (widget.parentIdToolController.text.isNotEmpty) {
      await fetchDataFromApi(widget.parentIdToolController.text);
    }
    
    // Lakukan validasi sederhana di sisi client
    setState(() {
      _isValidating = false;
      isNoCatridgeValid = true;
      noCatridgeError = '';
      // Note: We don't set scan state here - it should be set only after scanning
      // because we want it to be set only after scanning
    });
  }

  Future<void> _validateNoSeal() async {
    setState(() {
      _isValidating = true;
      noSealError = ''; // Reset error message
    });
    
    // Get the seal code
    final sealCode = noSealController.text;
    
    // Basic validation - ensure it's not empty
    if (sealCode.isEmpty) {
      setState(() {
        isNoSealValid = false;
        noSealError = 'Nomor Seal tidak boleh kosong';
        _isValidating = false;
      });
      return;
    }
    
    // Lakukan validasi sederhana di sisi client
    setState(() {
      _isValidating = false;
      isNoSealValid = true;
      noSealError = '';
      // Note: We don't set scan state here - it should be set only after scanning
      // because we want it to be set only after scanning
    });
  }

  void _validateCatridgeFisik() {
    final value = catridgeFisikController.text;
    setState(() {
      isCatridgeFisikValid = value.isNotEmpty;
      catridgeFisikError = value.isEmpty ? 'Catridge Fisik tidak boleh kosong' : '';
    });
  }

  void _validateKondisiSeal(String? value) {
    setState(() {
      kondisiSeal = value;
      isKondisiSealValid = value != null;
      kondisiSealError = value == null ? 'Pilih kondisi seal' : '';
    });
  }

  void _validateKondisiCatridge(String? value) {
    setState(() {
      kondisiCatridge = value;
      isKondisiCatridgeValid = value != null;
      kondisiCatridgeError = value == null ? 'Pilih kondisi catridge' : '';
    });
  }

  void _validateBagCode() {
    setState(() {
      isBagCodeValid = bagCodeController.text.isNotEmpty;
      bagCodeError = bagCodeController.text.isEmpty ? 'Bag Code tidak boleh kosong' : '';
    });
  }

  void _validateSealCodeReturn() {
    setState(() {
      isSealCodeReturnValid = sealCodeReturnController.text.isNotEmpty;
      sealCodeReturnError = sealCodeReturnController.text.isEmpty ? 'Seal Code Return tidak boleh kosong' : '';
    });
  }

  void _validateDenom(String key, TextEditingController controller) {
    // Validate denom input
    final value = controller.text;
    if (value.isNotEmpty) {
      try {
        int.parse(value); // Ensure it's a valid number
      } catch (e) {
        setState(() {
          isDenomValid = false;
          denomError = 'Nilai denom harus berupa angka';
        });
        return;
      }
    }
    
    setState(() {
      isDenomValid = true;
      denomError = '';
    });
    
    _calculateTotals();
  }

  void _calculateTotals() {
    int totalLembar = 0;
    int totalNominal = 0;
    
    denomControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        try {
          final count = int.parse(controller.text);
          totalLembar += count;
          
          // Calculate nominal based on denom
          int denomValue = 0;
          switch (key) {
            case '100K':
              denomValue = 100000;
              break;
            case '75K':
              denomValue = 75000;
              break;
            case '50K':
              denomValue = 50000;
              break;
            case '20K':
              denomValue = 20000;
              break;
            case '10K':
              denomValue = 10000;
              break;
            case '5K':
              denomValue = 5000;
              break;
            case '2K':
              denomValue = 2000;
              break;
            case '1K':
              denomValue = 1000;
              break;
          }
          
          totalNominal += count * denomValue;
        } catch (e) {
          // Ignore parsing errors here
        }
      }
    });
    
    // Update the totals display
    // We'll implement this in the next step
  }

  @override
  void didUpdateWidget(CartridgeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadReturnData();
  }

  void _loadReturnData() {
    print('📊 _loadReturnData() called');
    if (widget.returnData != null) {
      print('📊 Loading return data...');
      setState(() {
        _isValidating = true;
      });
      
      print('📊 Setting controller values...');
      noCatridgeController.text = widget.returnData!.catridgeCode;
      noSealController.text = widget.returnData!.catridgeSeal;
      // Clear catridgeFisik field - it will be filled by scanning
      catridgeFisikController.text = '';
      
      // If bagCode is available, use it
      if (widget.returnData!.bagCode != null) {
        bagCodeController.text = widget.returnData!.bagCode!;
      }
      
      // Set sealCodeReturn from API response
      if (widget.returnData!.sealCodeReturn != null) {
        sealCodeReturnController.text = widget.returnData!.sealCodeReturn!;
      }
      
      print('📊 Controller values set: noCatridge="${noCatridgeController.text}", noSeal="${noSealController.text}", bagCode="${bagCodeController.text}", sealCode="${sealCodeReturnController.text}"');
      
      // Reset validation state for pre-filled fields
      isNoCatridgeValid = noCatridgeController.text.isNotEmpty;
      isNoSealValid = noSealController.text.isNotEmpty;
      isCatridgeFisikValid = false; // This needs to be scanned
      isBagCodeValid = bagCodeController.text.isNotEmpty;
      isSealCodeReturnValid = sealCodeReturnController.text.isNotEmpty;
      
      print('📊 Validation flags set: isNoCatridgeValid=$isNoCatridgeValid, isNoSealValid=$isNoSealValid, isBagCodeValid=$isBagCodeValid, isSealCodeReturnValid=$isSealCodeReturnValid');
      
      // IMPORTANT: Reset all scanned fields flags because user needs to validate by scanning
      print('📊 BEFORE RESET: scannedFields = $scannedFields');
      scannedFields.forEach((key, value) {
        scannedFields[key] = false;
      });
      print('📊 AFTER RESET: scannedFields = $scannedFields');
      
      print('Scan states reset after loading data:');
      print('Scanned fields: $scannedFields');
      print('Loaded data - noCatridge: ${noCatridgeController.text}, noSeal: ${noSealController.text}, bagCode: ${bagCodeController.text}, sealCode: ${sealCodeReturnController.text}');
      
      setState(() {
        _isValidating = false;
      });
      print('📊 _loadReturnData() completed');
    } else {
      print('📊 No return data to load');
    }
  }

  // Check if all forms are valid
  bool get isFormValid {
    bool formIsValid = isNoCatridgeValid && 
           isNoSealValid && 
           isCatridgeFisikValid && 
           isKondisiSealValid && 
           isKondisiCatridgeValid && 
           isBagCodeValid && 
           isSealCodeReturnValid && 
           isDenomValid &&
           noCatridgeController.text.isNotEmpty &&
           noSealController.text.isNotEmpty &&
           catridgeFisikController.text.isNotEmpty &&
           kondisiSeal != null &&
           kondisiCatridge != null &&
           bagCodeController.text.isNotEmpty &&
           sealCodeReturnController.text.isNotEmpty &&
           // Check if required fields have been scanned
           scannedFields['noCatridge'] == true &&
           scannedFields['noSeal'] == true &&
           scannedFields['bagCode'] == true &&
           scannedFields['sealCode'] == true;
           
    // Log validation status for debugging
    if (!formIsValid) {
      print('Form validation failed. Scan status: $scannedFields');
      print('Required fields scanned: noCatridge=${scannedFields['noCatridge']}, noSeal=${scannedFields['noSeal']}, bagCode=${scannedFields['bagCode']}, sealCode=${scannedFields['sealCode']}');
    }
    
    return formIsValid;
  }

  // Add validation method for scanned codes
  bool _validateScannedCode(String scannedCode, TextEditingController controller) {
    // If controller is empty, any code is valid (first scan)
    if (controller.text.isEmpty) {
      return true;
    }
    
    // Otherwise, scanned code must match the existing value
    bool isValid = scannedCode == controller.text;
    print('Validating scanned code: $scannedCode against ${controller.text} - isValid: $isValid');
    return isValid;
  }
  
  // Add barcode scanner functionality for validation
  Future<void> _openBarcodeScanner(String label, TextEditingController controller, String fieldKey) async {
    try {
      print('Opening barcode scanner for field: $label');
      print('BEFORE SCAN: Field $fieldKey scan status: ${scannedFields[fieldKey]}');
      print('BEFORE SCAN: Controller text: ${controller.text}');
      
      // Clean field label for display
      String cleanLabel = label.replaceAll(':', '').trim();
      
      // Navigate to barcode scanner
      final result = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeScannerWidget(
            title: 'Scan $cleanLabel',
            onBarcodeDetected: (String barcode) {
              // Just return the barcode to handle in parent method
              Navigator.of(context).pop(barcode);
            },
          ),
        ),
      );
      
      // If barcode was scanned
      if (result != null && result.isNotEmpty) {
        print('Scanned barcode for $cleanLabel: $result');
        
        // Validate the scanned barcode matches the expected value
        bool isValid = true;
        String validationMessage = '';
        
        if (controller.text.isNotEmpty) {
          isValid = result == controller.text;
          if (!isValid) {
            validationMessage = 'Kode tidak sesuai! Harap scan kode yang sesuai dengan $cleanLabel.\nExpected: ${controller.text}\nScanned: $result';
          }
        }
        
        if (!isValid) {
          // Show error if scanned code doesn't match
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(validationMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
        
        // Update the field with scanned barcode if it was empty
        if (controller.text.isEmpty) {
          controller.text = result;
        }
        
        // Update the scanned status with setState to trigger UI update
        setState(() {
          // IMPORTANT: Directly update the scannedFields map
          scannedFields[fieldKey] = true;
          print('✅ SCAN SUCCESS: $fieldKey = $result (validated)');
          
          // Set field-specific validation flags
          if (label.contains('No. Catridge')) {
            isNoCatridgeValid = true;
            noCatridgeError = '';
          } else if (label.contains('No. Seal')) {
            isNoSealValid = true;
            noSealError = '';
          } else if (label.contains('Bag Code')) {
            isBagCodeValid = true;
            bagCodeError = '';
          } else if (label.contains('Seal Code')) {
            isSealCodeReturnValid = true;
            sealCodeReturnError = '';
          }
        });
        
        // Force rebuild to ensure checkmark displays properly  
        _forceRebuild();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $cleanLabel berhasil divalidasi: $result'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        print('AFTER SUCCESSFUL SCAN: Field $fieldKey scan status: ${scannedFields[fieldKey]}');
      } else {
        print('No barcode scanned or scan cancelled for $cleanLabel');
      }
      
    } catch (e) {
      print('Error opening barcode scanner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka scanner: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Add barcode scanner functionality for input fields (not validation)
  Future<void> _openBarcodeScannerForInput(String label, TextEditingController controller, String fieldKey) async {
    try {
      print('Opening barcode scanner for input field: $label');
      print('BEFORE SCAN INPUT: Field $fieldKey scan status: ${scannedFields[fieldKey]}');
      
      // Clean field label for display
      String cleanLabel = label.replaceAll(':', '').trim();
      
      // Navigate to barcode scanner
      final result = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeScannerWidget(
            title: 'Scan $cleanLabel',
            forceShowCheckmark: false, // FIX: Let scanner close itself
            onBarcodeDetected: (String barcode) {
              // Just return the barcode to handle in parent method
              Navigator.of(context).pop(barcode);
            },
          ),
        ),
      );
      
      // If barcode was scanned
      if (result != null && result.isNotEmpty) {
        print('Scanned barcode for $cleanLabel: $result');
        
        // Update the field with scanned barcode
        controller.text = result;
        
        // Update the scanned status with setState to trigger UI update
        setState(() {
          // IMPORTANT: Directly update the scannedFields map
          print('📝 INPUT SCAN - BEFORE UPDATE: scannedFields[$fieldKey] = ${scannedFields[fieldKey]}');
          scannedFields[fieldKey] = true;
          print('📝 INPUT SCAN - AFTER UPDATE: scannedFields[$fieldKey] = ${scannedFields[fieldKey]}');
          print('📝 INPUT SCAN - FULL MAP: $scannedFields');
          print('INPUT SCAN SUCCESS: Field $fieldKey marked as scanned with value: $result');
          print('SCAN STATUS MAP: $scannedFields');
          
          if (label.contains('Catridge Fisik')) {
            isCatridgeFisikValid = true;
            catridgeFisikError = '';
            print('✅ Set isCatridgeFisikValid = true');
          }
        });
        
        print('🔄 INPUT SCAN - About to call _forceRebuild()');
        // Force rebuild to ensure checkmark displays properly
        _forceRebuild();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $cleanLabel berhasil diisi: $result'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        print('AFTER SUCCESSFUL INPUT SCAN: Field $fieldKey scan status: ${scannedFields[fieldKey]}');
      } else {
        print('No barcode scanned or scan cancelled for $cleanLabel');
      }
      
    } catch (e) {
      print('Error opening barcode scanner: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka scanner: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this method to the _CartridgeSectionState class
  Future<void> _scanAndValidateField(String fieldName, TextEditingController controller) async {
    try {
      final result = await Navigator.push<String?>(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeScannerWidget(
            title: 'Scan $fieldName',
            forceShowCheckmark: false, // FIX: Let scanner close itself
            onBarcodeDetected: (String barcode) {
              // Just return the barcode and handle it in the parent method
              Navigator.of(context).pop(barcode);
            },
          ),
        ),
      );

      if (result != null && result.isNotEmpty) {
        print('Scanned barcode for $fieldName: $result');
        
        // Update the controller text
        controller.text = result;
        
        // Get the field key based on the controller
        String fieldKey = '';
        if (controller == noCatridgeController) {
          fieldKey = 'noCatridge';
        } else if (controller == noSealController) {
          fieldKey = 'noSeal';
        } else if (controller == catridgeFisikController) {
          fieldKey = 'catridgeFisik';
        } else if (controller == bagCodeController) {
          fieldKey = 'bagCode';
        } else if (controller == sealCodeReturnController) {
          fieldKey = 'sealCode';
        }
        
        if (fieldKey.isNotEmpty) {
          // Update the scan status
          setState(() {
            scannedFields[fieldKey] = true;
            print('Updated scan status for $fieldKey to true');
            print('Current scan status: $scannedFields');
          });
          
          // Force rebuild to ensure checkmark displays properly
          _forceRebuild();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$fieldName berhasil di-scan'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('Scan cancelled or empty result for $fieldName');
      }
    } catch (e) {
      print('Error scanning $fieldName: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShow = widget.returnData != null || widget.title == 'Catridge 1';
    
    if (!shouldShow) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
              ),
                ),
              // Remove the type: replenish_data text
            ],
          ),
          const SizedBox(height: 12),
          
              // Hidden branch code field
              Opacity(
                opacity: 0,
                child: SizedBox(
                  height: 0,
                  width: 0,
                  child: TextField(
                    controller: branchCodeController,
                    enabled: false,
                  ),
                ),
              ),
          
          // Two-column layout for fields
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          // No Catridge input field
          _buildInputField(
            'No. Catridge',
            noCatridgeController,
            onEditingComplete: _validateNoCatridge,
            isValid: isNoCatridgeValid,
            errorText: noCatridgeError,
            hasScanner: true,
            isLoading: _isValidating,
            readOnly: true, // Make it read-only
          ),
          
          const SizedBox(height: 12),
          
          // No Seal input field
          _buildInputField(
            'No. Seal',
            noSealController,
            onEditingComplete: _validateNoSeal,
            isValid: isNoSealValid,
            errorText: noSealError,
            hasScanner: true,
            isLoading: _isValidating,
            readOnly: true, // Make it read-only
          ),
          
          const SizedBox(height: 12),
          
          // Catridge Fisik input field
          _buildInputField(
            'Catridge Fisik',
            catridgeFisikController,
            onEditingComplete: _validateCatridgeFisik,
            isValid: isCatridgeFisikValid,
            errorText: catridgeFisikError,
            isScanInput: true, // Use scan input mode for this field
            hasScanner: true, // Add scanner
          ),
          
          const SizedBox(height: 12),
          
                    // Bag Code input field (replaced dropdown with text field)
                    _buildInputField(
                      'Bag Code',
                      bagCodeController,
                      onEditingComplete: _validateBagCode,
                      isValid: isBagCodeValid,
                      errorText: bagCodeError,
                      hasScanner: true, // Add scanner for bag code
                      readOnly: true, // Make it read-only
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Seal Code Return input field (replaced dropdown with text field)
                    _buildInputField(
            'Seal Code',
                      sealCodeReturnController,
                      onEditingComplete: _validateSealCodeReturn,
                      isValid: isSealCodeReturnValid,
                      errorText: sealCodeReturnError,
                      hasScanner: true, // Add scanner for seal code
                      readOnly: true, // Make it read-only
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 20),
              
              // Right column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Remove WSID field
          
                    // Kondisi Seal dropdown
          _buildDropdownField(
                      'Kondisi Seal',
                      kondisiSeal,
                      kondisiSealOptions,
                      (val) => _validateKondisiSeal(val),
                      isValid: isKondisiSealValid,
                      errorText: kondisiSealError,
          ),
          
          const SizedBox(height: 12),
                    
                    // Kondisi Catridge dropdown (reduced to two options)
                    _buildDropdownField(
                      'Kondisi Catridge',
                      kondisiCatridge,
                      kondisiCatridgeOptions,
                      (val) => _validateKondisiCatridge(val),
                      isValid: isKondisiCatridgeValid,
                      errorText: kondisiCatridgeError,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Denom fields
          const Text(
            'Denom',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          if (denomError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                denomError,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: denomControllers.entries.map((entry) {
              return SizedBox(
                width: 60,
                child: TextField(
                  controller: entry.value,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: entry.key,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 8),
                  ),
                  onEditingComplete: () => _validateDenom(entry.key, entry.value),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  // Simple input field with validation
  Widget _buildInputField(
    String label,
    TextEditingController controller,
    {VoidCallback? onEditingComplete,
    bool isValid = true,
    String errorText = '',
    bool hasScanner = false,
    bool isLoading = false,
    bool readOnly = false,
    bool isScanInput = false}
  ) {
    // Determine which field key to use
    String fieldKey = '';
    if (label.contains('No. Catridge')) {
      fieldKey = 'noCatridge';
    } else if (label.contains('No. Seal')) {
      fieldKey = 'noSeal';
    } else if (label.contains('Bag Code')) {
      fieldKey = 'bagCode';
    } else if (label.contains('Seal Code')) {
      fieldKey = 'sealCode';
    } else if (label.contains('Catridge Fisik')) {
      fieldKey = 'catridgeFisik';
    }
    
    // Check if this field has been scanned
    bool isScanned = fieldKey.isNotEmpty && scannedFields[fieldKey] == true;
    
    // Determine if we should show checkmark
    bool showCheckmark = isScanned && controller.text.isNotEmpty;
    
    // Debug only when checkmark should show
    if (showCheckmark) {
      print('✅ CHECKMARK VISIBLE: $label (scanned: $isScanned, hasText: ${controller.text.isNotEmpty})');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                '$label:',
                style: TextStyle(
                  fontWeight: isValid ? FontWeight.normal : FontWeight.bold,
                  color: isValid ? Colors.black : Colors.red,
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Masukkan $label',
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                  // Show loading indicator when validating (but NOT checkmark here)
                  suffixIcon: isLoading
                      ? Transform.scale(
                          scale: 0.5,
                          child: const CircularProgressIndicator(),
                        )
                      : null, // Remove checkmark from suffixIcon
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isValid ? Colors.grey : Colors.red,
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                onEditingComplete: onEditingComplete,
                readOnly: isScanInput ? false : readOnly, // Don't make scan input fields read-only
              ),
            ),
            // SEPARATE CHECKMARK WIDGET - This should be more reliable
            if (showCheckmark)
              Container(
                margin: const EdgeInsets.only(left: 8, bottom: 4),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16.0,
                ),
              ),
            if (hasScanner || isScanInput)
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                onPressed: () {
                  print('🔍 SCANNER BUTTON PRESSED for $label (fieldKey: $fieldKey)');
                  // Implement barcode scanning
                  if (isScanInput) {
                    _openBarcodeScannerForInput(label, controller, fieldKey);
                  } else {
                    _openBarcodeScanner(label, controller, fieldKey);
                  }
                },
              ),
            // DEBUG: Add test button for web testing (when camera doesn't work)
            if ((hasScanner || isScanInput) && controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.orange),
                tooltip: 'Test Validate (Debug)',
                onPressed: () {
                  print('🧪 DEBUG TEST BUTTON PRESSED for $label (fieldKey: $fieldKey)');
                  // Simulate successful scan validation
                  setState(() {
                    print('🧪 DEBUG: Simulating scan validation for $fieldKey');
                    scannedFields[fieldKey] = true;
                    print('🧪 DEBUG: scannedFields[$fieldKey] = ${scannedFields[fieldKey]}');
                    
                    // Set field-specific validation flags
                    if (label.contains('No. Catridge')) {
                      isNoCatridgeValid = true;
                      noCatridgeError = '';
                    } else if (label.contains('No. Seal')) {
                      isNoSealValid = true;
                      noSealError = '';
                    } else if (label.contains('Bag Code')) {
                      isBagCodeValid = true;
                      bagCodeError = '';
                    } else if (label.contains('Seal Code')) {
                      isSealCodeReturnValid = true;
                      sealCodeReturnError = '';
                    } else if (label.contains('Catridge Fisik')) {
                      isCatridgeFisikValid = true;
                      catridgeFisikError = '';
                    }
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🧪 DEBUG: $label validated!'),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
          ],
        ),
        if (errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 110, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  // Simple dropdown field with validation
  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> options,
    Function(String?) onChanged,
    {bool isValid = true,
    String errorText = ''}
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                '$label:',
                style: TextStyle(
                  fontWeight: isValid ? FontWeight.normal : FontWeight.bold,
                  color: isValid ? Colors.black : Colors.red,
                ),
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: value,
                hint: Text('Pilih $label'),
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  isDense: true,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: isValid ? Colors.grey : Colors.red,
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
                items: options.map<DropdownMenuItem<String>>((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(val),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        if (errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 110, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class DetailSection extends StatelessWidget {
  final ReturnHeaderResponse? returnData;
  final VoidCallback? onSubmitPressed;
  
  const DetailSection({
    Key? key, 
    this.returnData,
    this.onSubmitPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final greenTextStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.green[700],
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail WSID',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildLabelValue('WSID', returnData?.header?.atmCode ?? ''),
          _buildLabelValue('Bank', returnData?.header?.namaBank ?? ''),
          _buildLabelValue('Lokasi', returnData?.header?.lokasi ?? ''),
          const SizedBox(height: 12),
          _buildLabelValue('ATM Type', returnData?.header?.typeATM ?? ''),
          _buildLabelValue('Jenis Mesin', ''),
          _buildLabelValue('Tgl. Unload', ''),
          const Divider(height: 24, thickness: 1),
          const Text(
            'Detail Return',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Seluruh Lembar (Denom)',
                      style: greenTextStyle,
                    ),
                    const SizedBox(height: 8),
                    ..._buildDenomFields(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Seluruh Nominal (Denom)',
                      style: greenTextStyle,
                    ),
                    const SizedBox(height: 8),
                    ..._buildNominalFields(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Text(
                'Grand Total :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Text('Rp'),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: returnData != null ? onSubmitPressed : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Submit Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label :',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDenomFields() {
    final denomLabels = ['100K', '75K', '50K', '20K', '10K', '5K', '2K', '1K'];
    return denomLabels
        .map(
          (label) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      // Use underlined style for consistency
                      border: UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Lembar'),
              ],
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildNominalFields() {
    final denomLabels = ['100K', '75K', '50K', '20K', '10K', '5K', '2K', '1K'];
    return denomLabels
        .map(
          (label) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Text(': Rp'),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      // Use underlined style for consistency
                      border: UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}

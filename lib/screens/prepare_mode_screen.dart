import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prepare_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/barcode_scanner_widget.dart';

class PrepareModePage extends StatefulWidget {
  const PrepareModePage({Key? key}) : super(key: key);

  @override
  State<PrepareModePage> createState() => _PrepareModePageState();
}

class _PrepareModePageState extends State<PrepareModePage> {
  final TextEditingController _idCRFController = TextEditingController();
  final TextEditingController _jamMulaiController = TextEditingController();
  
  // API service
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  // Data from API
  ATMPrepareReplenishData? _prepareData;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Dynamic list of catridge controllers
  List<List<TextEditingController>> _catridgeControllers = [];
  
  // Denom values for each catridge
  List<int> _denomValues = [];
  
  // Catridge data from lookup
  List<CatridgeData?> _catridgeData = [];
  
  // Detail catridge data for the right panel
  List<DetailCatridgeItem> _detailCatridgeItems = [];
  
  // Approval form state
  bool _showApprovalForm = false;
  bool _isSubmitting = false;
  final TextEditingController _nikTLController = TextEditingController();
  final TextEditingController _passwordTLController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Lock orientation to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Initialize with one empty catridge
    _initializeCatridgeControllers(1);
    
    // Set current time as jam mulai
    _setCurrentTime();
  }

  @override
  void dispose() {
    _idCRFController.dispose();
    _jamMulaiController.dispose();
    
    // Dispose all dynamic controllers
    for (var controllerList in _catridgeControllers) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    
    // Dispose approval form controllers
    _nikTLController.dispose();
    _passwordTLController.dispose();
    
    super.dispose();
  }
  
  // Set current time
  void _setCurrentTime() {
    final now = DateTime.now();
    _jamMulaiController.text = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // Initialize controllers for catridges
  void _initializeCatridgeControllers(int count) {
    // Clear existing controllers first
    for (var controllerList in _catridgeControllers) {
      for (var controller in controllerList) {
        controller.dispose();
      }
    }
    
    _catridgeControllers = [];
    _denomValues = List.filled(count, 0);
    _catridgeData = List.filled(count, null);
    
    // Create new controllers for each catridge
    for (int i = 0; i < count; i++) {
      _catridgeControllers.add([
        TextEditingController(), // No Catridge
        TextEditingController(), // Seal Catridge
        TextEditingController(), // Bag Code
        TextEditingController(), // Seal Code
        TextEditingController(), // Seal Code Return
      ]);
    }
  }
  
  // Step 1: Lookup catridge and create initial detail item
  Future<void> _lookupCatridgeAndCreateDetail(int catridgeIndex, String catridgeCode) async {
    if (catridgeCode.isEmpty || !mounted) return;
    
    try {
      print('=== STEP 1: LOOKUP CATRIDGE ===');
      print('Catridge Index: $catridgeIndex');
      print('Catridge Code: $catridgeCode');
      
      // Get branch code
      String branchCode = "1"; // Default
      if (_prepareData != null && _prepareData!.branchCode.isNotEmpty) {
        branchCode = _prepareData!.branchCode;
      }
      
      // Get required standValue from prepare data for validation
      int? requiredStandValue = _prepareData?.standValue;
      
      print('Using requiredStandValue for validation: $requiredStandValue');
      
      final response = await _apiService.getCatridgeDetails(
        branchCode, 
        catridgeCode, 
        requiredStandValue: requiredStandValue
      );
      
      print('Catridge lookup response: ${response.success}, data count: ${response.data.length}, message: ${response.message}');
      
      if (response.success && response.data.isNotEmpty && mounted) {
        final catridgeData = response.data.first;
        print('Found catridge: ${catridgeData.code}');
        
        // Calculate denom amount
        String tipeDenom = _prepareData?.tipeDenom ?? 'A50';
        int denomAmount = 0;
        String denomText = '';
        
        if (tipeDenom == 'A50') {
          denomAmount = 50000;
          denomText = 'Rp 50.000';
        } else if (tipeDenom == 'A100') {
          denomAmount = 100000;
          denomText = 'Rp 100.000';
        } else {
          denomAmount = 50000;
          denomText = 'Rp 50.000';
        }
        
        // Use standValue from prepare data
        int actualStandValue = _prepareData?.standValue ?? 0;
        
        // Calculate total
        int totalNominal = denomAmount * actualStandValue;
        String formattedTotal = _formatCurrency(totalNominal);
        
        // Auto-populate seal if available from prepare data
        String autoSeal = '';
        if (_prepareData != null && catridgeIndex == 0) {
          // For first catridge, try to use seal from prepare data
          if (_prepareData!.catridgeSeal.isNotEmpty) {
            autoSeal = _prepareData!.catridgeSeal;
            // Also populate the controller
            if (_catridgeControllers.length > catridgeIndex && _catridgeControllers[catridgeIndex].length > 1) {
              _catridgeControllers[catridgeIndex][1].text = autoSeal;
            }
          }
        }
        
        // Create initial detail item
        final detailItem = DetailCatridgeItem(
          index: catridgeIndex + 1,
          noCatridge: catridgeCode,
          sealCatridge: autoSeal, // Auto-populated or empty
          value: actualStandValue,
          total: formattedTotal,
          denom: denomText,
        );
        
        setState(() {
          // Store catridge data for reference
          _catridgeData[catridgeIndex] = catridgeData;
          
          // Check if item already exists for this index
          int existingIndex = _detailCatridgeItems.indexWhere((item) => item.index == catridgeIndex + 1);
          if (existingIndex >= 0) {
            // Update existing item but keep seal if already filled
            var existingItem = _detailCatridgeItems[existingIndex];
            _detailCatridgeItems[existingIndex] = DetailCatridgeItem(
              index: detailItem.index,
              noCatridge: detailItem.noCatridge,
              sealCatridge: existingItem.sealCatridge, // Keep existing seal
              value: detailItem.value,
              total: detailItem.total,
              denom: detailItem.denom,
            );
            print('Updated existing detail item at index $existingIndex');
          } else {
            // Add new item
            _detailCatridgeItems.add(detailItem);
            print('Added new detail item: ${detailItem.noCatridge}');
          }
          
          // Sort by index
          _detailCatridgeItems.sort((a, b) => a.index.compareTo(b.index));
          print('Total detail items now: ${_detailCatridgeItems.length}');
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catridge found: ${catridgeData.code}')),
        );
      } else {
        // Handle API response error or empty data
        String errorMessage = 'Catridge tidak ditemukan';
        if (!response.success && response.message.isNotEmpty) {
          // Use API error message if available
          errorMessage = response.message;
        } else if (response.success && response.data.isEmpty) {
          // Empty data with success response (should not happen with new logic)
          errorMessage = 'Catridge tidak ditemukan atau tidak sesuai kriteria';
        }
        
        // Create error detail item
        _createErrorDetailItem(catridgeIndex, catridgeCode, errorMessage);
        
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error looking up catridge: $e');
      _createErrorDetailItem(catridgeIndex, catridgeCode, 'Error: ${e.toString()}');
    }
  }
  
  // Step 2: Validate seal and update detail item using comprehensive validation
  Future<void> _validateSealAndUpdateDetail(int catridgeIndex, String sealCode) async {
    if (sealCode.isEmpty || !mounted) return;
    
    try {
      print('=== STEP 2: COMPREHENSIVE SEAL VALIDATION ===');
      print('Catridge Index: $catridgeIndex');
      print('Seal Code: $sealCode');
      
      final response = await _apiService.validateSeal(sealCode);
      
      print('Seal validation response: ${response.success}');
      print('Seal validation message: ${response.message}');
      print('Validation data: ${response.data?.validationStatus}');
      print('Error code: ${response.data?.errorCode}');
      print('Error message: ${response.data?.errorMessage}');
      print('Validated seal code: ${response.data?.validatedSealCode}');
      
      if (response.success && response.data != null && response.data!.validationStatus == 'SUCCESS' && mounted) {
        // Validation successful - update with validated seal code
        setState(() {
          int existingIndex = _detailCatridgeItems.indexWhere((item) => item.index == catridgeIndex + 1);
          if (existingIndex >= 0) {
            var existingItem = _detailCatridgeItems[existingIndex];
            _detailCatridgeItems[existingIndex] = DetailCatridgeItem(
              index: existingItem.index,
              noCatridge: existingItem.noCatridge,
              sealCatridge: response.data!.validatedSealCode, // Use validated seal code
              value: existingItem.value,
              total: existingItem.total,
              denom: existingItem.denom,
            );
            print('Updated seal for detail item at index $existingIndex with validated code: ${response.data!.validatedSealCode}');
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seal berhasil divalidasi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Validation failed - update detail item with error from SP
        String errorMessage = 'Seal tidak valid';
        if (response.data != null && response.data!.errorMessage.isNotEmpty) {
          errorMessage = response.data!.errorMessage;
        } else if (response.message.isNotEmpty) {
          errorMessage = response.message;
        }
        
        setState(() {
          int existingIndex = _detailCatridgeItems.indexWhere((item) => item.index == catridgeIndex + 1);
          if (existingIndex >= 0) {
            var existingItem = _detailCatridgeItems[existingIndex];
            _detailCatridgeItems[existingIndex] = DetailCatridgeItem(
              index: existingItem.index,
              noCatridge: existingItem.noCatridge,
              sealCatridge: 'Error: $errorMessage', // Show error from SP
              value: existingItem.value,
              total: existingItem.total,
              denom: existingItem.denom,
            );
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validasi seal gagal: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error validating seal: $e');
      // Update detail item with network/system error
      setState(() {
        int existingIndex = _detailCatridgeItems.indexWhere((item) => item.index == catridgeIndex + 1);
        if (existingIndex >= 0) {
          var existingItem = _detailCatridgeItems[existingIndex];
          _detailCatridgeItems[existingIndex] = DetailCatridgeItem(
            index: existingItem.index,
            noCatridge: existingItem.noCatridge,
            sealCatridge: 'Error: ${e.toString()}', // Show system error
            value: existingItem.value,
            total: existingItem.total,
            denom: existingItem.denom,
          );
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kesalahan sistem: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Helper method to create error detail item
  void _createErrorDetailItem(int catridgeIndex, String catridgeCode, String errorMessage) {
    final detailItem = DetailCatridgeItem(
      index: catridgeIndex + 1,
      noCatridge: catridgeCode.isNotEmpty ? catridgeCode : 'Error',
      sealCatridge: '',
      value: 0,
      total: errorMessage, // Show error in total field
      denom: '',
    );
    
    setState(() {
      int existingIndex = _detailCatridgeItems.indexWhere((item) => item.index == catridgeIndex + 1);
      if (existingIndex >= 0) {
        _detailCatridgeItems[existingIndex] = detailItem;
      } else {
        _detailCatridgeItems.add(detailItem);
      }
      
      _detailCatridgeItems.sort((a, b) => a.index.compareTo(b.index));
      print('Created error detail item: $errorMessage');
    });
  }
  
  // Remove detail catridge item
  void _removeDetailCatridgeItem(int index) {
    setState(() {
      _detailCatridgeItems.removeWhere((item) => item.index == index);
    });
  }
  
  // Check if all detail catridge items are valid and complete
  bool _areAllCatridgeItemsValid() {
    if (_detailCatridgeItems.isEmpty) return false;
    
    for (var item in _detailCatridgeItems) {
      // Check if item has error
      if (item.total.contains('Error') || item.total.contains('tidak ditemukan') ||
          item.sealCatridge.contains('Error') || item.sealCatridge.contains('tidak valid')) {
        print('Item has error: ${item.noCatridge}');
        return false;
      }
      
      // Check if all required fields are filled
      if (item.noCatridge.isEmpty || item.sealCatridge.isEmpty || item.value <= 0) {
        print('Item is incomplete: noCatridge=${item.noCatridge.isEmpty}, sealCatridge=${item.sealCatridge.isEmpty}, value=${item.value}');
        return false;
      }
    }
    
    return true;
  }
  
  // Show approval form
  void _showApprovalFormDialog() {
    setState(() {
      _showApprovalForm = true;
    });
  }
  
  // Hide approval form
  void _hideApprovalForm() {
    setState(() {
      _showApprovalForm = false;
      _nikTLController.clear();
      _passwordTLController.clear();
    });
  }
  
  // Submit data with approval
  Future<void> _submitDataWithApproval() async {
    if (_nikTLController.text.isEmpty || _passwordTLController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIK TL SPV dan Password harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      // Step 1: Update Planning API
      print('=== STEP 1: UPDATE PLANNING ===');
      final planningResponse = await _apiService.updatePlanning(
        idTool: _prepareData!.id,
        cashierCode: 'CURRENT_USER', // TODO: Get from auth service
        spvTLCode: _nikTLController.text,
        tableCode: _prepareData!.tableCode,
      );
      
      if (!planningResponse.success) {
        throw Exception('Planning update failed: ${planningResponse.message}');
      }
      
      print('Planning update success: ${planningResponse.message}');
      
      // Step 2: Insert ATM Catridge for each detail item
      print('=== STEP 2: INSERT ATM CATRIDGE ===');
      List<String> successMessages = [];
      List<String> errorMessages = [];
      
      for (int i = 0; i < _detailCatridgeItems.length; i++) {
        var item = _detailCatridgeItems[i];
        print('Processing catridge ${i + 1}: ${item.noCatridge}');
        
        // Get data from form fields for this catridge
        String bagCode = '';
        String sealCode = '';
        String sealReturn = '';
        
        // Get data from controllers if available
        if (i < _catridgeControllers.length) {
          bagCode = _catridgeControllers[i][2].text.trim(); // Bag Code field
          sealCode = _catridgeControllers[i][3].text.trim(); // Seal Code field
          sealReturn = _catridgeControllers[i][4].text.trim(); // Seal Code Return field
        }
        
        // Fallback to prepare data if form fields are empty
        if (bagCode.isEmpty) bagCode = _prepareData!.bagCode;
        if (sealCode.isEmpty) sealCode = _prepareData!.sealCode;
        // sealReturn MUST come from form field only - no fallback to TEST
        
        // Final validation - ensure no empty critical fields
        if (bagCode.isEmpty) bagCode = 'TEST';
        if (sealCode.isEmpty) sealCode = 'TEST';
        // Do NOT set sealReturn to TEST - it must be from form field only
        
        // Get current user data for userInput
        String userInput = 'UNKNOWN';
        try {
          final userData = await _authService.getUserData();
          if (userData != null) {
            // Try to get NIK first, then username as fallback
            userInput = userData['nik'] ?? userData['username'] ?? userData['userCode'] ?? 'UNKNOWN';
          }
        } catch (e) {
          print('Error getting user data: $e');
          userInput = 'UNKNOWN';
        }
        
        // Ensure denomination code is not empty
        String finalDenomCode = _prepareData!.denomCode;
        if (finalDenomCode.isEmpty) finalDenomCode = 'TEST';
        
        // Ensure catridge seal is not empty
        String finalCatridgeSeal = item.sealCatridge;
        if (finalCatridgeSeal.isEmpty || finalCatridgeSeal.contains('Error')) {
          finalCatridgeSeal = 'TEST';
        }
        
        print('Catridge ${i + 1} data:');
        print('  bagCode: $bagCode');
        print('  sealCode: $sealCode');
        print('  sealReturn: $sealReturn (from form field only)');
        print('  catridgeSeal: $finalCatridgeSeal');
        print('  denomCode: $finalDenomCode');
        print('  qty: ${item.value}');
        print('  userInput: $userInput (from logged-in user)');
        
        // Validate required fields before API call
        if (sealReturn.isEmpty) {
          errorMessages.add('Catridge ${i + 1}: Seal Code Return harus diisi');
          print('Catridge ${i + 1} error: Seal Code Return is empty');
          continue; // Skip this catridge and continue to next
        }
        
        try {
          final catridgeResponse = await _apiService.insertAtmCatridge(
            idTool: _prepareData!.id,
            bagCode: bagCode,
            catridgeCode: item.noCatridge,
            sealCode: sealCode,
            catridgeSeal: finalCatridgeSeal,
            denomCode: finalDenomCode,
            qty: item.value.toString(),
            userInput: userInput, // Use actual logged-in user
            sealReturn: sealReturn, // Must be from form field only
            // Send TEST values for all 6 fields
            scanCatStatus: "TEST",
            scanCatStatusRemark: "TEST",
            scanSealStatus: "TEST", 
            scanSealStatusRemark: "TEST",
            difCatAlasan: "TEST",
            difCatRemark: "TEST",
          );
          
          if (catridgeResponse.success) {
            successMessages.add('Catridge ${i + 1}: ${catridgeResponse.message}');
            print('Catridge ${i + 1} success: ${catridgeResponse.message}');
          } else {
            errorMessages.add('Catridge ${i + 1}: ${catridgeResponse.message}');
            print('Catridge ${i + 1} error: ${catridgeResponse.message}');
          }
        } catch (e) {
          errorMessages.add('Catridge ${i + 1}: ${e.toString()}');
          print('Catridge ${i + 1} exception: $e');
        }
      }
      
      // Show results
      if (errorMessages.isEmpty) {
        // All success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Semua data berhasil disimpan!\n${successMessages.join('\n')}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        
        // Hide approval form and potentially navigate back or reset form
        _hideApprovalForm();
        
        // TODO: Navigate back or reset form
        Navigator.of(context).pop();
        
      } else if (successMessages.isEmpty) {
        // All failed
        throw Exception('Semua catridge gagal disimpan:\n${errorMessages.join('\n')}');
      } else {
        // Mixed results
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sebagian data berhasil disimpan:\nBerhasil: ${successMessages.length}\nGagal: ${errorMessages.length}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
        
        _hideApprovalForm();
      }
      
    } catch (e) {
      print('Submit error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
  
  // Fetch data from API
  Future<void> _fetchPrepareData() async {
    if (_idCRFController.text.isEmpty || !mounted) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Please enter ID CRF';
        });
      }
      return;
    }
    
    int id;
    try {
      id = int.parse(_idCRFController.text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Invalid ID format. Please enter a number.';
        });
      }
      return;
    }
    
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    
    try {
      final response = await _apiService.getATMPrepareReplenish(id);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success && response.data != null) {
            _prepareData = response.data;
            
            // Initialize controllers based on jmlKaset
            int kasetCount = _prepareData!.jmlKaset;
            if (kasetCount <= 0) kasetCount = 1; // Ensure at least 1 catridge
            
            _initializeCatridgeControllers(kasetCount);
            
            // Set jam mulai to current time
            _setCurrentTime();
            
            // Populate catridge fields if data is available
            if (_catridgeControllers.isNotEmpty && _prepareData!.catridgeCode.isNotEmpty) {
              _catridgeControllers[0][0].text = _prepareData!.catridgeCode;
              _catridgeControllers[0][1].text = _prepareData!.catridgeSeal;
              _catridgeControllers[0][2].text = _prepareData!.bagCode;
              _catridgeControllers[0][3].text = _prepareData!.sealCode;
            }
            
            // Note: standValue is now taken directly from _prepareData.standValue
            // No need to store in _denomValues array
          } else {
            _errorMessage = response.message;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
        });
        
        // If unauthorized, navigate back to login
        if (e.toString().contains('Unauthorized')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session expired. Please login again.')),
          );
          
          // Clear token and navigate back
          await _authService.logout();
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layout
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header section with back button, title, and user info
            _buildHeader(context, isSmallScreen),
            
            // Error message if any
            if (_errorMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                color: Colors.red.shade100,
                width: double.infinity,
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
            
            // Loading indicator
            if (_isLoading)
              const LinearProgressIndicator(),
            
            // Main content - Changes layout based on screen size
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  final useVerticalLayout = isSmallScreen || availableWidth < 800;
                  
                  return useVerticalLayout
                    ? SingleChildScrollView(
                        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: availableHeight - 32, // Account for padding
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Form header fields
                              _buildFormHeaderFields(isSmallScreen),
                              
                              SizedBox(height: isSmallScreen ? 8 : 16),
                              
                              // Left side - Catridge forms
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Dynamic catridge sections
                                  for (int i = 0; i < _catridgeControllers.length; i++)
                                    _buildCatridgeSection(i + 1, _catridgeControllers[i], _denomValues[i], isSmallScreen),
                                ],
                              ),
                              
                              // Horizontal divider
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                height: 1,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              
                              // Right side - Details
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Detail WSID section
                                  _buildDetailWSIDSection(isSmallScreen),
                                  
                                  // Detail Catridge section
                                  _buildDetailCatridgeSection(isSmallScreen),
                                  
                                  // Approval TL Supervisor form
                                  if (_showApprovalForm)
                                    _buildApprovalForm(isSmallScreen),
                                  
                                  // Grand Total and Submit button
                                  _buildTotalAndSubmitSection(isSmallScreen),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side - Catridge forms
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Form header fields
                                    _buildFormHeaderFields(isSmallScreen),
                                    
                                    // Dynamic catridge sections
                                    for (int i = 0; i < _catridgeControllers.length; i++)
                                      _buildCatridgeSection(i + 1, _catridgeControllers[i], _denomValues[i], isSmallScreen),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Vertical divider
                          Container(
                            width: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          
                          // Right side - Details
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Detail WSID section
                                    _buildDetailWSIDSection(isSmallScreen),
                                    
                                    // Detail Catridge section
                                    _buildDetailCatridgeSection(isSmallScreen),
                                    
                                    // Approval TL Supervisor form
                                    if (_showApprovalForm)
                                      _buildApprovalForm(isSmallScreen),
                                    
                                    // Grand Total and Submit button
                                    _buildTotalAndSubmitSection(isSmallScreen),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                }
              ),
            ),
            
            // Footer
            _buildFooter(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 16.0, 
        vertical: isSmallScreen ? 4.0 : 8.0
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back, 
              color: Colors.red, 
              size: isSmallScreen ? 20 : 30
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: isSmallScreen ? 32 : 48),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          SizedBox(width: isSmallScreen ? 4 : 8),
          
          // Title
          Text(
            'Prepare Mode',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // Location and user info - For small screens, show minimal info
          if (isSmallScreen)
            // Compact header for small screens
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'JAKARTA-CIDENG',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Meja: 010101',
                      style: TextStyle(fontSize: 8),
                    ),
                    SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CRF_OPR',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            // Full header for larger screens
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'JAKARTA-CIDENG',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Meja : 010101',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'CRF_OPR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          
          SizedBox(width: isSmallScreen ? 4 : 16),
          
          // User avatar and info - Simplified for small screens
          if (isSmallScreen)
            // Just show avatar for small screens
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: const AssetImage('assets/images/user.jpg'),
              onBackgroundImageError: (exception, stackTrace) {},
            )
          else
            // Full user info for larger screens
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: const AssetImage('assets/images/user.jpg'),
                    onBackgroundImageError: (exception, stackTrace) {},
                  ),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lorenzo Putra',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '9180812021',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFormHeaderFields(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8.0 : 16.0),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ID CRF field - removed search button
                _buildFormField(
                  label: 'ID CRF :',
                  controller: _idCRFController,
                  hasIcon: false,
                  isSmallScreen: isSmallScreen,
                  enableScan: true,
                ),
                
                const SizedBox(height: 8),
                
                // Jam Mulai field with time icon
                _buildFormField(
                  label: 'Jam Mulai :',
                  controller: _jamMulaiController,
                  hasIcon: true,
                  iconData: Icons.access_time,
                  isSmallScreen: isSmallScreen,
                ),
                
                const SizedBox(height: 8),
                
                // Tanggal Replenish field (disabled/read-only)
                _buildFormField(
                  label: 'Tanggal Replenish :',
                  readOnly: true,
                  hintText: '―',
                  isSmallScreen: isSmallScreen,
                ),
              ],
            )
          : Row(
              children: [
                // ID CRF field - removed search button
                Expanded(
                  child: _buildFormField(
                    label: 'ID CRF :',
                    controller: _idCRFController,
                    hasIcon: false,
                    isSmallScreen: isSmallScreen,
                    enableScan: true,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Jam Mulai field with time icon
                Expanded(
                  child: _buildFormField(
                    label: 'Jam Mulai :',
                    controller: _jamMulaiController,
                    hasIcon: true,
                    iconData: Icons.access_time,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Tanggal Replenish field (disabled/read-only)
                Expanded(
                  child: _buildFormField(
                    label: 'Tanggal Replenish :',
                    readOnly: true,
                    hintText: '―',
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCatridgeSection(
    int index, 
    List<TextEditingController> controllers, 
    int denomValue,
    bool isSmallScreen
  ) {
    // Get tipeDenom from API data if available
    String? tipeDenom = _prepareData?.tipeDenom;
    int standValue = _prepareData?.standValue ?? 0;
    
    // Convert tipeDenom to rupiah value
    String denomText = '';
    int denomAmount = 0;
    
    // Only show denom values if _prepareData is available
    if (_prepareData != null && tipeDenom != null) {
      if (tipeDenom == 'A50') {
        denomText = 'Rp 50.000';
        denomAmount = 50000;
      } else if (tipeDenom == 'A100') {
        denomText = 'Rp 100.000';
        denomAmount = 100000;
      } else {
        // Default fallback
        denomText = 'Rp 50.000';
        denomAmount = 50000;
      }
    } else {
      // Empty state when no data is available
      denomText = '—';
    }
    
    // Calculate total nominal using standValue from prepare data
    String formattedTotal = '—';
    int actualValue = _prepareData?.standValue ?? 0;
    
    if (denomAmount > 0 && actualValue > 0) {
      int totalNominal = denomAmount * actualValue;
      formattedTotal = _formatCurrency(totalNominal);
    }
    
    // Determine image path based on tipeDenom
    String? imagePath;
    if (_prepareData != null && tipeDenom != null) {
      imagePath = 'assets/images/${tipeDenom}.png';
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 10 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catridge title with Denom indicator on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  'Catridge $index',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                flex: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Denom',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 8),
                    Flexible(
                      child: Text(
                        denomText,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 15),
          
          // Fields with denom section on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - All 5 fields in single column (vertical) - made narrower
              Expanded(
                flex: isSmallScreen ? 3 : 3, // Increased from 2 to 3
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // No. Catridge field
                    _buildCompactField(
                      label: 'No. Catridge', 
                      controller: controllers[0],
                      isSmallScreen: isSmallScreen,
                      catridgeIndex: index - 1,
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 10),
                    
                    // Seal Catridge field
                    _buildCompactField(
                      label: 'Seal Catridge', 
                      controller: controllers[1],
                      isSmallScreen: isSmallScreen,
                      catridgeIndex: index - 1,
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 10),
                    
                    // Bag Code field
                    _buildCompactField(
                      label: 'Bag Code', 
                      controller: controllers[2],
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 10),
                    
                    // Seal Code field
                    _buildCompactField(
                      label: 'Seal Code', 
                      controller: controllers[3],
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 10),
                    
                    // Seal Code Return field
                    if (controllers.length >= 5)
                      _buildCompactField(
                        label: 'Seal Code Return', 
                        controller: controllers[4],
                        isSmallScreen: isSmallScreen,
                      ),
                  ],
                ),
              ),
              
              SizedBox(width: isSmallScreen ? 12 : 16),
              
              // Right side - Denom details with image and total - balanced width
              Expanded(
                flex: isSmallScreen ? 2 : 2, // Reduced from 2:3 to 3:2
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Money image - adjusted size
                    Container(
                      height: isSmallScreen ? 110 : 135,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _prepareData == null || imagePath == null
                        ? Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: isSmallScreen ? 45 : 60,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.currency_exchange,
                                    size: isSmallScreen ? 45 : 60,
                                    color: Colors.blue,
                                  ),
                                  SizedBox(height: isSmallScreen ? 5 : 8),
                                  Text(
                                    denomText,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            },
                          ),
                    ),
                    
                    // Value and Lembar info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 9 : 11),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Value',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _prepareData?.standValue != null && _prepareData!.standValue > 0
                              ? _prepareData!.standValue.toString()
                              : '—',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15,
                            ),
                          ),
                          Text(
                            'Lembar',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Total Nominal box
                    Container(
                      margin: EdgeInsets.only(top: isSmallScreen ? 11 : 16),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 11 : 13, 
                        horizontal: isSmallScreen ? 9 : 11
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFDCF8C6),  // Light green background
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Total Nominal',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 13 : 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 5 : 8),
                          Text(
                            formattedTotal,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 17,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Divider at the bottom
          Padding(
            padding: EdgeInsets.only(top: isSmallScreen ? 15 : 25),
            child: Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to format currency
  String _formatCurrency(int amount) {
    String value = amount.toString();
    String result = '';
    int count = 0;
    
    for (int i = value.length - 1; i >= 0; i--) {
      count++;
      result = value[i] + result;
      if (count % 3 == 0 && i > 0) {
        result = '.$result';
      }
    }
    
    return 'Rp $result';
  }

  // Helper method to build compact field (for inline layout with underline)
  Widget _buildCompactField({
    required String label,
    required TextEditingController controller,
    required bool isSmallScreen,
    int? catridgeIndex,
  }) {
    return Container(
      height: isSmallScreen ? 32 : 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Label section - fixed width
          SizedBox(
            width: isSmallScreen ? 85 : 100,
            child: Padding(
              padding: EdgeInsets.only(bottom: isSmallScreen ? 4 : 6),
              child: Text(
                '$label :',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // Input field section with underline - expandable
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.only(
                          left: isSmallScreen ? 4 : 6,
                          right: isSmallScreen ? 4 : 6,
                          bottom: isSmallScreen ? 4 : 6,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        // Step 1: If this is a catridge code field, lookup catridge and create detail
                        if (label == 'No. Catridge' && catridgeIndex != null) {
                          print('No. Catridge changed: $value for index $catridgeIndex');
                          // Debounce the lookup to avoid too many API calls
                          Future.delayed(Duration(milliseconds: 500), () {
                            if (controller.text == value && value.isNotEmpty) {
                              _lookupCatridgeAndCreateDetail(catridgeIndex, value);
                            }
                          });
                        }
                        // Step 2: If this is a seal catridge field, validate seal and update detail
                        else if (label == 'Seal Catridge' && catridgeIndex != null) {
                          print('Seal Catridge changed: $value for index $catridgeIndex');
                          // Debounce the validation to avoid too many API calls
                          Future.delayed(Duration(milliseconds: 500), () {
                            if (controller.text == value && value.isNotEmpty) {
                              _validateSealAndUpdateDetail(catridgeIndex, value);
                            }
                          });
                        }
                      },
                    ),
                  ),
                  // Scan barcode icon button - positioned on the underline
                  Container(
                    width: isSmallScreen ? 20 : 24,
                    height: isSmallScreen ? 20 : 24,
                    margin: EdgeInsets.only(
                      left: isSmallScreen ? 4 : 6,
                      bottom: isSmallScreen ? 2 : 3,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.qr_code_scanner,
                        size: isSmallScreen ? 12 : 16,
                        color: Colors.blue.shade600,
                      ),
                      onPressed: () => _openBarcodeScanner(label, controller),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailWSIDSection(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail WSID',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 15),
          
          _buildDetailRow('WSID', _prepareData?.atmCode ?? '-', isSmallScreen),
          _buildDetailRow('Bank', _prepareData?.codeBank ?? '-', isSmallScreen),
          _buildDetailRow('Lokasi', _prepareData?.lokasi ?? '-', isSmallScreen),
          _buildDetailRow('ATM Type', _prepareData?.jnsMesin ?? '-', isSmallScreen),
          _buildDetailRow('Jumlah Kaset', '${_prepareData?.jmlKaset ?? 0}', isSmallScreen),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 4 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 80 : 100,
            child: Text(
              '$label :',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailCatridgeSection(bool isSmallScreen) {
    // Debug logging
    print('=== BUILDING DETAIL CATRIDGE SECTION ===');
    print('Detail catridge items count: ${_detailCatridgeItems.length}');
    for (int i = 0; i < _detailCatridgeItems.length; i++) {
      print('Item $i: ${_detailCatridgeItems[i].noCatridge} - ${_detailCatridgeItems[i].sealCatridge}');
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detail Catridge',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 15),
          
          // Display detail catridge items
          if (_detailCatridgeItems.isNotEmpty)
            ..._detailCatridgeItems.map((item) => _buildDetailCatridgeItem(item, isSmallScreen)).toList()
          else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'No catridge data available (${_detailCatridgeItems.length} items)',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildDetailCatridgeItem(DetailCatridgeItem item, bool isSmallScreen) {
    // Check if this is an error item
    bool isError = item.total.contains('Error') || item.total.contains('tidak ditemukan') || 
                   item.sealCatridge.contains('Error') || item.sealCatridge.contains('tidak valid');
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
      decoration: BoxDecoration(
        border: Border.all(color: isError ? Colors.red.shade300 : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Catridge number, Denom and trash icon
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: isError ? Colors.red.shade50 : Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              border: Border(
                bottom: BorderSide(color: isError ? Colors.red.shade300 : Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${item.index}. Catridge ${item.index}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: isError ? Colors.red.shade700 : null,
                      ),
                    ),
                    SizedBox(width: 20),
                    if (!isError)
                      Text(
                        'Denom : ${item.denom}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: isSmallScreen ? 16 : 18,
                      ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: isSmallScreen ? 16 : 18,
                    ),
                    onPressed: () => _removeDetailCatridgeItem(item.index),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Detail fields
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            child: Column(
              children: [
                _buildDetailItemRow('No. Catridge', item.noCatridge, isSmallScreen, isError),
                SizedBox(height: isSmallScreen ? 6 : 8),
                _buildDetailItemRow('Seal Catridge', item.sealCatridge, isSmallScreen, isError),
                SizedBox(height: isSmallScreen ? 6 : 8),
                _buildDetailItemRow('Value', item.value.toString(), isSmallScreen, isError),
                SizedBox(height: isSmallScreen ? 6 : 8),
                _buildDetailItemRow('Total', item.total, isSmallScreen, isError),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItemRow(String label, String value, bool isSmallScreen, [bool isError = false]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isSmallScreen ? 100 : 120,
          child: Text(
            '$label :',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: isError ? Colors.red.shade700 : null,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: isError && (value.contains('Error') || value.contains('tidak')) 
                     ? Colors.red.shade700 : null,
              fontWeight: isError && (value.contains('Error') || value.contains('tidak'))
                        ? FontWeight.w500 : null,
            ),
          ),
        ),
      ],
    );
  }
  
  // Build Approval TL Supervisor form
  Widget _buildApprovalForm(bool isSmallScreen) {
    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 15 : 25, top: isSmallScreen ? 10 : 15),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.green.shade700,
                size: isSmallScreen ? 20 : 24,
              ),
              SizedBox(width: 8),
              Text(
                'Approval TL Supervisor',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          // NIK TL SPV Field
          _buildApprovalField(
            label: 'NIK TL SPV',
            controller: _nikTLController,
            isSmallScreen: isSmallScreen,
            icon: Icons.person,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          // Password Field
          _buildApprovalField(
            label: 'Password',
            controller: _passwordTLController,
            isSmallScreen: isSmallScreen,
            icon: Icons.lock,
            isPassword: true,
          ),
          
          SizedBox(height: isSmallScreen ? 16 : 20),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cancel button
              TextButton(
                onPressed: _isSubmitting ? null : _hideApprovalForm,
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              // Submit button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5AE25A), Color(0xFF29CC29)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitDataWithApproval,
                  icon: _isSubmitting 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.check, size: isSmallScreen ? 16 : 18),
                  label: Text(
                    _isSubmitting ? 'Processing...' : 'Approve & Submit',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 8 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Helper method to build approval form fields
  Widget _buildApprovalField({
    required String label,
    required TextEditingController controller,
    required bool isSmallScreen,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: isSmallScreen ? 36 : 40,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.green.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              SizedBox(width: 12),
              Icon(
                icon,
                size: isSmallScreen ? 16 : 18,
                color: Colors.green.shade600,
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword,
                  enabled: !_isSubmitting,
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: isPassword ? '••••••••••' : 'Enter $label',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }

  
  Widget _buildTotalAndSubmitSection(bool isSmallScreen) {
    // Add debugging for submit button validation
    print('=== SUBMIT BUTTON CHECK ===');
    print('_prepareData is null: ${_prepareData == null}');
    print('_detailCatridgeItems.length: ${_detailCatridgeItems.length}');
    if (_detailCatridgeItems.isNotEmpty) {
      for (int i = 0; i < _detailCatridgeItems.length; i++) {
        var item = _detailCatridgeItems[i];
        print('Item $i: ${item.noCatridge} - ${item.sealCatridge} - ${item.value} - ${item.total}');
      }
    }
    bool isValid = _areAllCatridgeItemsValid();
    print('_areAllCatridgeItemsValid(): $isValid');
    
    // Jika belum ada data, tampilkan tanda strip
    if (_prepareData == null) {
      return Padding(
        padding: EdgeInsets.only(top: isSmallScreen ? 10 : 25),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Grand Total
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Grand Total :',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 6 : 15),
                Text(
                  '—',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: isSmallScreen ? 8 : 0),
            
            // Submit button with arrow icon
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [Color(0xFF5AE25A), Color(0xFF29CC29)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _areAllCatridgeItemsValid() ? _showApprovalFormDialog : null,
                icon: Icon(Icons.arrow_forward, size: isSmallScreen ? 14 : 16),
                label: Text(
                  'Submit Data',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 24, 
                    vertical: isSmallScreen ? 6 : 12
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Get tipeDenom from API data if available
    String tipeDenom = _prepareData?.tipeDenom ?? 'A50';
    int standValue = _prepareData?.standValue ?? 0;
    
    // Convert tipeDenom to rupiah value
    int denomAmount = 0;
    if (tipeDenom == 'A50') {
      denomAmount = 50000;
    } else if (tipeDenom == 'A100') {
      denomAmount = 100000;
    } else {
      // Default fallback
      denomAmount = 50000;
    }
    
    // Calculate total from detail catridge items
    int totalAmount = 0;
    for (var item in _detailCatridgeItems) {
      // Parse total back to int (remove currency formatting)
      String cleanTotal = item.total.replaceAll('Rp ', '').replaceAll('.', '').trim();
      if (cleanTotal.isNotEmpty && cleanTotal != '0') {
        try {
          totalAmount += int.parse(cleanTotal);
        } catch (e) {
          // If parsing fails, calculate from value and denom
          String tipeDenom = _prepareData?.tipeDenom ?? 'A50';
          int denomAmount = tipeDenom == 'A100' ? 100000 : 50000;
          totalAmount += denomAmount * item.value;
        }
      }
    }
    
    String formattedTotal = totalAmount > 0 ? _formatCurrency(totalAmount) : '—';
    
    return Padding(
      padding: EdgeInsets.only(top: isSmallScreen ? 10 : 25),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Grand Total
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Grand Total :',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: isSmallScreen ? 6 : 15),
              Flexible(
                child: Text(
                  formattedTotal,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: isSmallScreen ? 8 : 0),
          
          // Submit button with arrow icon
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(
                colors: [Color(0xFF5AE25A), Color(0xFF29CC29)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _areAllCatridgeItemsValid() ? _showApprovalFormDialog : null,
              icon: Icon(Icons.arrow_forward, size: isSmallScreen ? 14 : 16),
              label: Text(
                'Submit Data',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 24, 
                  vertical: isSmallScreen ? 6 : 12
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFooter(bool isSmallScreen) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 4 : 10,
        horizontal: isSmallScreen ? 8 : 20,
      ),
      child: Row(
        children: [
          // Left side - version info
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'CASH REPLENISH FORM',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 10 : 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 4 : 8),
                Text(
                  'ver. 0.0.1',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 8 : 14,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Right side - logos
          Flexible(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/advantage_logo.png',
                  height: isSmallScreen ? 20 : 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: isSmallScreen ? 20 : 40,
                      width: isSmallScreen ? 60 : 120,
                      color: Colors.transparent,
                      child: Center(
                        child: Text(
                          'ADVANTAGE',
                          style: TextStyle(fontSize: isSmallScreen ? 8 : 12),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: isSmallScreen ? 6 : 20),
                Image.asset(
                  'assets/images/crf_logo.png',
                  height: isSmallScreen ? 20 : 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: isSmallScreen ? 20 : 40,
                      width: isSmallScreen ? 20 : 60,
                      color: Colors.transparent,
                      child: Center(
                        child: Text(
                          'CRF',
                          style: TextStyle(fontSize: isSmallScreen ? 8 : 12),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    TextEditingController? controller,
    bool readOnly = false,
    String? hintText,
    bool hasIcon = false,
    IconData iconData = Icons.search,
    VoidCallback? onIconPressed,
    required bool isSmallScreen,
    bool enableScan = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: isSmallScreen ? 36 : 45,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  decoration: InputDecoration(
                    hintText: hintText,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 12,
                      vertical: isSmallScreen ? 6 : 10,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    // Auto-trigger fetch data for ID CRF field
                    if (label == 'ID CRF :' && value.isNotEmpty) {
                      // Debounce the API call to avoid too many requests
                      Future.delayed(Duration(milliseconds: 800), () {
                        if (controller != null && controller.text == value && value.isNotEmpty) {
                          _fetchPrepareData();
                        }
                      });
                    }
                  },
                ),
              ),
              if (enableScan && controller != null)
                IconButton(
                  icon: Icon(
                    Icons.qr_code_scanner,
                    size: isSmallScreen ? 18 : 20,
                    color: Colors.blue.shade600,
                  ),
                  onPressed: () => _openBarcodeScanner(label, controller),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (hasIcon)
                IconButton(
                  icon: Icon(
                    iconData,
                    size: isSmallScreen ? 18 : 24,
                    color: Colors.grey.shade700,
                  ),
                  onPressed: onIconPressed,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              SizedBox(width: isSmallScreen ? 6 : 10),
            ],
          ),
        ),
      ],
    );
  }

  // Open barcode scanner for field input
  Future<void> _openBarcodeScanner(String fieldLabel, TextEditingController controller) async {
    try {
      print('Opening barcode scanner for field: $fieldLabel');
      
      // Clean field label for display
      String cleanLabel = fieldLabel.replaceAll(' :', '').trim();
      
      // Navigate to barcode scanner
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BarcodeScannerWidget(
            title: 'Scan $cleanLabel',
            onBarcodeDetected: (String barcode) {
              print('Barcode detected for $cleanLabel: $barcode');
              
              // Fill the field with scanned barcode
              setState(() {
                controller.text = barcode;
              });
              
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$cleanLabel berhasil diisi: $barcode'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              
              // Trigger the same logic as manual input
              if (cleanLabel == 'ID CRF') {
                // Trigger API call to fetch prepare data
                Future.delayed(Duration(milliseconds: 300), () {
                  _fetchPrepareData();
                });
              } else if (cleanLabel == 'No. Catridge') {
                // Find catridge index for this controller
                for (int i = 0; i < _catridgeControllers.length; i++) {
                  if (_catridgeControllers[i].isNotEmpty && _catridgeControllers[i][0] == controller) {
                    Future.delayed(Duration(milliseconds: 300), () {
                      _lookupCatridgeAndCreateDetail(i, barcode);
                    });
                    break;
                  }
                }
              } else if (cleanLabel == 'Seal Catridge') {
                // Find catridge index for this controller
                for (int i = 0; i < _catridgeControllers.length; i++) {
                  if (_catridgeControllers[i].length > 1 && _catridgeControllers[i][1] == controller) {
                    Future.delayed(Duration(milliseconds: 300), () {
                      _validateSealAndUpdateDetail(i, barcode);
                    });
                    break;
                  }
                }
              }
            },
          ),
        ),
      );
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
}







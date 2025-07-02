import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/prepare_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

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
  
  // Fetch data from API
  Future<void> _fetchPrepareData() async {
    if (_idCRFController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter ID CRF';
      });
      return;
    }
    
    int id;
    try {
      id = int.parse(_idCRFController.text);
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid ID format. Please enter a number.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final response = await _apiService.getATMPrepareReplenish(id);
      
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
          
          // Set denom values if available
          if (_denomValues.isNotEmpty) {
            _denomValues[0] = _prepareData!.value;
          }
        } else {
          _errorMessage = response.message;
        }
      });
    } catch (e) {
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
              child: isSmallScreen
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form header fields
                        _buildFormHeaderFields(isSmallScreen),
                        
                        // Left side - Catridge forms
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dynamic catridge sections
                              for (int i = 0; i < _catridgeControllers.length; i++)
                                _buildCatridgeSection(i + 1, _catridgeControllers[i], _denomValues[i], isSmallScreen),
                            ],
                          ),
                        ),
                        
                        // Horizontal divider
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          height: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        
                        // Right side - Details
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Detail WSID section
                              _buildDetailWSIDSection(isSmallScreen),
                              
                              // Detail Catridge section
                              _buildDetailCatridgeSection(isSmallScreen),
                              
                              // Grand Total and Submit button
                              _buildTotalAndSubmitSection(isSmallScreen),
                            ],
                          ),
                        ),
                      ],
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
                                
                                // Grand Total and Submit button
                                _buildTotalAndSubmitSection(isSmallScreen),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
              size: isSmallScreen ? 24 : 30
            ),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          // Title
          Text(
            'Prepare Mode',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // Location and user info - For small screens, show minimal info
          if (isSmallScreen)
            // Compact header for small screens
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      'JAKARTA-CIDENG',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CRF_OPR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
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
          
          SizedBox(width: isSmallScreen ? 8 : 16),
          
          // User avatar and info - Simplified for small screens
          if (isSmallScreen)
            // Just show avatar for small screens
            CircleAvatar(
              radius: 15,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: const AssetImage('assets/images/user.jpg'),
              onBackgroundImageError: (exception, stackTrace) {},
            )
          else
            // Full user info for larger screens
            Row(
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
                // ID CRF field with search functionality
                _buildFormField(
                  label: 'ID CRF :',
                  controller: _idCRFController,
                  hasIcon: true,
                  onIconPressed: _fetchPrepareData,
                  isSmallScreen: isSmallScreen,
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
                // ID CRF field with search functionality
                Expanded(
                  child: _buildFormField(
                    label: 'ID CRF :',
                    controller: _idCRFController,
                    hasIcon: true,
                    onIconPressed: _fetchPrepareData,
                    isSmallScreen: isSmallScreen,
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
    
    // Calculate total nominal only if we have valid data
    String formattedTotal = '—';
    if (_prepareData != null && denomAmount > 0 && standValue > 0) {
      int totalNominal = denomAmount * standValue;
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
              Text(
                'Catridge $index',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Denom',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    denomText,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 15),
          
          // Fields with denom section on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - All fields in a vertical column with inline labels
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // No. Catridge field - inline style
                    _buildInlineField(
                      label: 'No. Catridge', 
                      controller: controllers[0],
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: 8),
                    
                    // Seal Catridge field - inline style
                    _buildInlineField(
                      label: 'Seal Catridge', 
                      controller: controllers[1],
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: 8),
                    
                    // Bag Code field - inline style
                    _buildInlineField(
                      label: 'Bag Code', 
                      controller: controllers[2],
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: 8),
                    
                    // Seal Code field - inline style
                    _buildInlineField(
                      label: 'Seal Code', 
                      controller: controllers[3],
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: 8),
                    
                    // Additional field - Seal Code Return at the bottom - inline style
                    if (controllers.length >= 5)
                      _buildInlineField(
                        label: 'Seal Code Return', 
                        controller: controllers[4],
                        isSmallScreen: isSmallScreen,
                      ),
                  ],
                ),
              ),
              
              // Right side - Denom details with image and total
              Expanded(
                flex: 2,
                child: Container(
                  margin: EdgeInsets.only(left: isSmallScreen ? 5 : 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Money image
                      Container(
                        height: 100,
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _prepareData == null || imagePath == null
                          ? Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 40,
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
                                      size: 40,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      denomText,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                      ),
                      
                      // Value and Lembar info
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 8),
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
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _prepareData == null ? '—' : standValue.toString(),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            Text(
                              'Lembar',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Total Nominal box
                      Container(
                        margin: EdgeInsets.only(top: 15),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Color(0xFFDCF8C6),  // Light green background
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Total Nominal',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formattedTotal,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

  // Helper method to build inline field (label and field on same row)
  Widget _buildInlineField({
    required String label,
    required TextEditingController controller,
    required bool isSmallScreen,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Label - fixed width
        Container(
          width: isSmallScreen ? 100 : 120,
          child: Text(
            '$label',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Colon
        Text(
          ':',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(width: 10),
        
        // Field
        Expanded(
          child: Container(
            height: isSmallScreen ? 36 : 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                      ),
                      border: InputBorder.none,

                    ),
                  ),

                ),
                // Copy icon button
                IconButton(
                  icon: Icon(
                    Icons.content_copy,
                    size: isSmallScreen ? 18 : 20,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    // Copy functionality
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: isSmallScreen ? 6 : 10),
              ],
            ),
          ),
        ),
      ],
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
          
          if (_prepareData != null) 
            _buildAllCatridgeDetails(isSmallScreen)
          else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'No catridge data available',
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAllCatridgeDetails(bool isSmallScreen) {
    // Jumlah kaset dari API
    final int jmlKaset = _prepareData?.jmlKaset ?? 0;
    
    // Data catridge yang ada dari API
    final List<CatridgeDetail> existingCatridges = _prepareData?.listCatridge ?? [];
    
    // Log untuk debugging
    debugPrint('jmlKaset dari API: $jmlKaset');
    debugPrint('Jumlah catridges yang ada: ${existingCatridges.length}');
    
    // Jika tidak ada data sama sekali, tampilkan pesan kosong
    if (jmlKaset <= 0 && existingCatridges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          'No catridge data available',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    // Tentukan jumlah catridge yang harus ditampilkan
    // Gunakan nilai terbesar antara jmlKaset atau panjang list catridge
    final int catridgeCount = jmlKaset > existingCatridges.length ? jmlKaset : existingCatridges.length;
    
    debugPrint('Total catridge yang akan ditampilkan: $catridgeCount');
    
    // Generate daftar catridge untuk ditampilkan
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(catridgeCount, (index) {
        // Jika index masih dalam jangkauan list yang ada, gunakan data tersebut
        if (index < existingCatridges.length) {
          final catridge = existingCatridges[index];
          return _buildCatridgeDetailRow(catridge, isSmallScreen, index + 1);
        } 
        // Jika tidak ada data untuk index ini, buat catridge placeholder
        else {
          return _buildEmptyCatridgeDetailRow(isSmallScreen, index + 1);
        }
      }),
    );
  }
  
  Widget _buildCatridgeDetailRow(CatridgeDetail catridge, bool isSmallScreen, int displayIndex) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catridge $displayIndex',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Value: ${catridge.value}',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                Text(
                  'Denom: ${catridge.denom}',
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
                if (catridge.code.isNotEmpty)
                  Text(
                    'Code: ${catridge.code}',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                if (catridge.seal.isNotEmpty)
                  Text(
                    'Seal: ${catridge.seal}',
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget untuk menampilkan catridge yang belum ada datanya
  Widget _buildEmptyCatridgeDetailRow(bool isSmallScreen, int displayIndex) {
    return Padding(
      padding: EdgeInsets.only(bottom: isSmallScreen ? 4 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catridge $displayIndex',
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              '(Data not available)',
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
  
  Widget _buildTotalAndSubmitSection(bool isSmallScreen) {
    // Jika belum ada data, tampilkan tanda strip
    if (_prepareData == null) {
      return Padding(
        padding: EdgeInsets.only(top: isSmallScreen ? 15 : 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Grand Total
            Row(
              children: [
                Text(
                  'Grand Total :',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 15),
                Text(
                  '—',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            
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
                onPressed: () {
                  // Submit functionality
                },
                icon: const Icon(Icons.arrow_forward),
                label: Text(
                  'Submit Data',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 24, 
                    vertical: isSmallScreen ? 8 : 12
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
    
    // Calculate total from all catridges
    int totalAmount = denomAmount * standValue * _catridgeControllers.length;
    String formattedTotal = _formatCurrency(totalAmount);
    
    return Padding(
      padding: EdgeInsets.only(top: isSmallScreen ? 15 : 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Grand Total
          Row(
            children: [
              Text(
                'Grand Total :',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 15),
              Text(
                formattedTotal,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          
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
              onPressed: () {
                // Submit functionality
              },
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                'Submit Data',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 24, 
                  vertical: isSmallScreen ? 8 : 12
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
        vertical: isSmallScreen ? 5 : 10,
        horizontal: isSmallScreen ? 10 : 20,
      ),
      child: Row(
        children: [
          // Left side - version info
          Row(
            children: [
              Text(
                'CASH REPLENISH FORM',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 12 : 16,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'ver. 0.0.1',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 14,
                ),
              ),
            ],
          ),
          
          const Spacer(),
          
          // Right side - logos
          Row(
            children: [
              Image.asset(
                'assets/images/advantage_logo.png',
                height: isSmallScreen ? 30 : 40,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isSmallScreen ? 30 : 40,
                    width: isSmallScreen ? 80 : 120,
                    color: Colors.transparent,
                    child: Center(child: Text('ADVANTAGE')),
                  );
                },
              ),
              SizedBox(width: isSmallScreen ? 10 : 20),
              Image.asset(
                'assets/images/crf_logo.png',
                height: isSmallScreen ? 30 : 40,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isSmallScreen ? 30 : 40,
                    width: isSmallScreen ? 40 : 60,
                    color: Colors.transparent,
                    child: Center(child: Text('CRF')),
                  );
                },
              ),
            ],
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
                ),
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
                  iconSize: isSmallScreen ? 18 : 24,
                ),
              SizedBox(width: isSmallScreen ? 6 : 10),
            ],
          ),
        ),
      ],
    );
  }
}






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
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header section with back button, title, and user info
            _buildHeader(context),
            
            // Error message if any
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade100,
                width: double.infinity,
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            
            // Loading indicator
            if (_isLoading)
              const LinearProgressIndicator(),
            
            // Main content
            Expanded(
              child: Row(
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
                            _buildFormHeaderFields(),
                            
                            // Dynamic catridge sections
                            for (int i = 0; i < _catridgeControllers.length; i++)
                              _buildCatridgeSection(i + 1, _catridgeControllers[i], _denomValues[i]),
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
                            _buildDetailWSIDSection(),
                            
                            // Detail Catridge section
                            _buildDetailCatridgeSection(),
                            
                            // Grand Total and Submit button
                            _buildTotalAndSubmitSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
            icon: const Icon(Icons.arrow_back, color: Colors.red, size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          // Title
          const Text(
            'Prepare Mode',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const Spacer(),
          
          // Location and user info
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
          
          const SizedBox(width: 16),
          
          // User avatar and info
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

  Widget _buildFormHeaderFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          // ID CRF field with search functionality
          Expanded(
            child: _buildFormField(
              label: 'ID CRF :',
              controller: _idCRFController,
              hasIcon: true,
              onIconPressed: _fetchPrepareData,
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Jam Mulai field
          Expanded(
            child: _buildFormField(
              label: 'Jam Mulai :',
              controller: _jamMulaiController,
              hasIcon: true,
              hasInfoIcon: true,
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Tanggal Replenish field
          Expanded(
            child: Row(
              children: [
                const Text(
                  'Tanggal Replenish :',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _prepareData?.dateReplenish != null
                      ? '${_prepareData!.dateReplenish!.day}/${_prepareData!.dateReplenish!.month}/${_prepareData!.dateReplenish!.year}'
                      : '-',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatridgeSection(int catridgeNumber, List<TextEditingController> controllers, int denomValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Catridge header with denom section
        Row(
          children: [
            Text(
              'Catridge $catridgeNumber',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            
            // Denom section (separated as requested)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Denom',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rp ${denomValue.toString()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const Divider(height: 1, thickness: 1),
        
        const SizedBox(height: 10),
        
        // Catridge form fields
        _buildFormField(
          label: 'No. Catridge',
          controller: controllers[0],
          hasIcon: true,
        ),
        
        const SizedBox(height: 10),
        
        _buildFormField(
          label: 'Seal Catridge',
          controller: controllers[1],
          hasIcon: true,
        ),
        
        const SizedBox(height: 10),
        
        _buildFormField(
          label: 'Bag Code',
          controller: controllers[2],
          hasIcon: true,
        ),
        
        const SizedBox(height: 10),
        
        _buildFormField(
          label: 'Seal Code',
          controller: controllers[3],
          hasIcon: true,
        ),
        
        const SizedBox(height: 10),
        
        _buildFormField(
          label: 'Seal Code Return',
          controller: controllers[4],
          hasIcon: true,
        ),
        
        const SizedBox(height: 16),
        
        // Value and Lembar
        Row(
          children: [
            const Spacer(),
            const Text(
              'Value',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 60),
            const Text(
              'Lembar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Total Nominal
        Center(
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Total Nominal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rp ${_prepareData?.total ?? 0}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Divider
        Container(
          height: 1,
          color: Colors.grey.shade300,
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailWSIDSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        // Detail WSID header
        const Text(
          '| Detail WSID',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // WSID and Bank info
        Row(
          children: [
            // WSID
            Expanded(
              child: Row(
                children: [
                  const Text(
                    'WSID',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(':'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _prepareData?.atmCode ?? '-',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            const Text('|'),
            
            // Bank
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Text(
                    'Bank',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(':'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _prepareData?.codeBank ?? '-',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Lokasi
        Row(
          children: [
            const Text(
              'Lokasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Text(':'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _prepareData?.lokasi ?? '-',
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // ATM Type
        Row(
          children: [
            const Text(
              'ATM Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Text(':'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _prepareData?.jnsMesin ?? '-',
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Jumlah Kaset
        Row(
          children: [
            const Text(
              'Jumlah Kaset',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Text(':'),
            const SizedBox(width: 8),
            Text(
              _prepareData?.jmlKaset.toString() ?? '0',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Divider
        Container(
          height: 1,
          color: Colors.grey.shade300,
        ),
      ],
    );
  }

  Widget _buildDetailCatridgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        
        // Detail Catridge header
        const Text(
          '| Detail Catridge',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Empty space for detail catridge content
        Container(
          height: 100,
          width: double.infinity,
          child: _prepareData != null ? 
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Catridge Code: ${_prepareData!.catridgeCode}'),
                Text('Type: ${_prepareData!.typeCatridge}'),
                Text('Denom: ${_prepareData!.denomCode}'),
                Text('Value: ${_prepareData!.value}'),
              ],
            ) : 
            const Center(child: Text('No catridge data available')),
        ),
      ],
    );
  }

  Widget _buildTotalAndSubmitSection() {
    // Calculate grand total
    int grandTotal = 0;
    if (_prepareData != null) {
      grandTotal = _prepareData!.total;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Grand Total
          Row(
            children: [
              const Text(
                'Grand Total :',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rp $grandTotal',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          // Submit Data button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
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
              onPressed: _prepareData != null ? () {
                // Handle submit
              } : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text(
                'Submit Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white.withOpacity(0.7),
      child: const Row(
        children: [
          Text(
            'CASH REPLENISH FORM   ver. 0.0.1',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    bool hasIcon = false,
    bool hasInfoIcon = false,
    VoidCallback? onIconPressed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      if (label == 'ID CRF :' && value.isNotEmpty) {
                        _fetchPrepareData();
                      }
                    },
                  ),
                ),
                if (hasIcon)
                  GestureDetector(
                    onTap: onIconPressed,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Icon(
                        label == 'ID CRF :' ? Icons.search : Icons.content_copy,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hasInfoIcon)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
      ],
    );
  }
}




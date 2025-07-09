import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/return_model.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }



  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserData();
      setState(() {
        if (userData != null) {
          _userData = userData;
          _branchCode = userData['branchCode'] ?? userData['BranchCode'] ?? '';
        } else {
          _branchCode = '';
        }
      });
    } catch (e) {
      setState(() {
        _branchCode = '';
      });
    }
  }

  Future<void> _fetchReturnData() async {
    final idCrf = _idCRFController.text.trim();
    if (idCrf.isEmpty) {
      setState(() { _errorMessage = 'ID CRF tidak boleh kosong'; });
      return;
    }
    if (_branchCode.isEmpty) {
      setState(() { _errorMessage = 'BranchCode tidak ditemukan'; });
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final response = await _apiService.getReturnHeaderAndCatridge(idCrf, branchCode: _branchCode);
      setState(() {
        _returnHeaderResponse = response;
        _errorMessage = response.success ? '' : response.message;
      });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _openBarcodeScanner() async {
    // TODO: Implementasi scan barcode dan set _idCRFController.text
  }

  Future<void> _submitReturnData() async {
    if (_returnHeaderResponse == null || _returnHeaderResponse!.data.isEmpty) {
      setState(() { _errorMessage = 'Tidak ada data untuk disubmit'; });
      return;
    }

    setState(() { _isLoading = true; _errorMessage = ''; });
    
    try {
      // Submit data untuk setiap cartridge
      for (var cartridgeData in _returnHeaderResponse!.data) {
        final response = await _apiService.insertReturnAtmCatridge(
          idTool: _idCRFController.text.trim(),
          bagCode: '', // TODO: Ambil dari input user
          catridgeCode: cartridgeData.catridgeCode,
          sealCode: '', // TODO: Ambil dari input user
          catridgeSeal: cartridgeData.catridgeSeal,
          denomCode: cartridgeData.denomCode,
          qty: '0', // TODO: Ambil dari input user
          userInput: _userData?['nik'] ?? '',
        );
        
        if (!response.success) {
          throw Exception(response.message);
        }
      }
      
      // Tampilkan dialog sukses
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sukses'),
          content: const Text('Data return berhasil disubmit'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form
                _idCRFController.clear();
                setState(() {
                  _returnHeaderResponse = null;
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
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
          // Input ID CRF di bawah header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text('ID CRF :', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: TextField(
                    controller: _idCRFController,
                    decoration: InputDecoration(
                      hintText: 'Masukkan ID CRF',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _fetchReturnData(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner, color: Colors.blue),
                  onPressed: _openBarcodeScanner,
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _fetchReturnData,
                  child: Text('Cari'),
                ),
              ],
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
            ),
          if (_isLoading)
            const LinearProgressIndicator(),
          // Tambahkan di bawah AppBar (tepat di bawah header)
          Padding(
            padding: const EdgeInsets.all(12),
            child: isTabletOrLandscapeMobile
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            CartridgeSection(
                              title: 'Catridge 1',
                              returnData: _returnHeaderResponse?.data.isNotEmpty == true ? _returnHeaderResponse!.data[0] : null,
                            ),
                            const SizedBox(height: 24),
                            CartridgeSection(
                              title: 'Catridge 2',
                              returnData: _returnHeaderResponse?.data.length == 2 ? _returnHeaderResponse!.data[1] : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: DetailSection(
                          returnData: _returnHeaderResponse,
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        CartridgeSection(
                          title: 'Catridge 1',
                          returnData: _returnHeaderResponse?.data.isNotEmpty == true ? _returnHeaderResponse!.data[0] : null,
                        ),
                        const SizedBox(height: 24),
                        CartridgeSection(
                          title: 'Catridge 2',
                          returnData: _returnHeaderResponse?.data.length == 2 ? _returnHeaderResponse!.data[1] : null,
                        ),
                        const SizedBox(height: 24),
                        DetailSection(
                          returnData: _returnHeaderResponse,
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

class CartridgeSection extends StatefulWidget {
  final String title;
  final ReturnCatridgeData? returnData;
  const CartridgeSection({Key? key, required this.title, this.returnData}) : super(key: key);

  @override
  State<CartridgeSection> createState() => _CartridgeSectionState();
}

class _CartridgeSectionState extends State<CartridgeSection> {
  String? kondisiSeal;
  String? kondisiCatridge;
  String? sealCode;
  String? bagCode;

  final List<String> kondisiSealOptions = ['Good', 'Bad', 'Unknown'];
  final List<String> kondisiCatridgeOptions = ['New', 'Used', 'Damaged'];
  final List<String> sealCodeOptions = ['Code A', 'Code B', 'Code C'];
  final List<String> bagCodeOptions = ['Bag 1', 'Bag 2', 'Bag 3'];

  final TextEditingController noCatridgeController = TextEditingController();
  final TextEditingController noSealController = TextEditingController();
  final TextEditingController catridgeFisikController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _loadReturnData();
  }

  @override
  void didUpdateWidget(CartridgeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadReturnData();
  }

  void _loadReturnData() {
    if (widget.returnData != null) {
      noCatridgeController.text = widget.returnData!.catridgeCode;
      noSealController.text = widget.returnData!.catridgeSeal;
      catridgeFisikController.text = widget.returnData!.typeCatridge;
    }
  }

  @override
  void dispose() {
    noCatridgeController.dispose();
    noSealController.dispose();
    catridgeFisikController.dispose();
    for (var c in denomControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              decoration: TextDecoration.underline,
              decorationThickness: 2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabelValueInput('No Catridge', noCatridgeController),
                    _buildLabelValueInput('No Seal', noSealController),
                    _buildDropdown('Kondisi Seal', kondisiSeal, kondisiSealOptions,
                        (val) {
                      setState(() {
                        kondisiSeal = val;
                      });
                    }),
                    const SizedBox(height: 8),
                    const Text(
                      'Denom',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right column
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdown('Kondisi Catridge', kondisiCatridge,
                        kondisiCatridgeOptions, (val) {
                      setState(() {
                        kondisiCatridge = val;
                      });
                    }),
                    _buildLabelValueInput('Catridge Fisik', catridgeFisikController),
                    _buildDropdown('Seal Code', sealCode, sealCodeOptions, (val) {
                      setState(() {
                        sealCode = val;
                      });
                    }),
                    _buildDropdown('Bag Code', bagCode, bagCodeOptions, (val) {
                      setState(() {
                        bagCode = val;
                      });
                    }),
                    const SizedBox(height: 24),
                    _buildLabelValueText('Total Lembar', '0'),
                    _buildLabelValueText('Total Nominal', '0'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValueInput(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label :',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> options,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label :',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              isDense: true,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                border: OutlineInputBorder(),
              ),
              items: options
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValueText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label :',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class DetailSection extends StatelessWidget {
  final ReturnHeaderResponse? returnData;
  const DetailSection({Key? key, this.returnData}) : super(key: key);

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
              onPressed: () {
                // Call submit method from parent widget
                if (context.findAncestorStateOfType<_ReturnModePageState>() != null) {
                  context.findAncestorStateOfType<_ReturnModePageState>()!._submitReturnData();
                }
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Submit Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(),
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
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      border: OutlineInputBorder(),
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

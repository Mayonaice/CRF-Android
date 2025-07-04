import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({Key? key}) : super(key: key);

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  String _deviceName = 'Xiaomi Tab 11';
  String _androidVersion = 'Android Versi 14';
  String _osVersion = 'HYPER OS 14';
  String _androidId = '1234Uas612343456';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Lock orientation to landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _deviceName = '${androidInfo.brand} ${androidInfo.model}';
          _androidVersion = 'Android Versi ${androidInfo.version.release}';
          _osVersion = androidInfo.version.codename ?? 'Android ${androidInfo.version.release}';
          _androidId = androidInfo.id ?? 'Unknown';
          _isLoading = false;
        });
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        setState(() {
          _deviceName = '${iosInfo.name} ${iosInfo.model}';
          _androidVersion = 'iOS ${iosInfo.systemVersion}';
          _osVersion = 'iOS ${iosInfo.systemVersion}';
          _androidId = iosInfo.identifierForVendor ?? 'Unknown';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error getting device info: $e');
    }
  }

  void _copyAndroidId() {
    Clipboard.setData(ClipboardData(text: _androidId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Android ID berhasil di Copy kedalam Clipboard !'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/bg-choosemenu.png'),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Wrapper box untuk navbar dan box putih dengan warna #A9D0D7
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFA9D0D7),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Top Navigation Bar
                  _buildTopNavigationBar(isSmallScreen),
                  
                  // Box putih dengan tinggi statis dan mepet di bawah navbar
                  Container(
                    height: isSmallScreen ? 400 : 480, // Tinggi untuk device info (lebih kecil dari profile)
                    margin: EdgeInsets.only(
                      top: 0, // Mepet dengan navbar
                      bottom: isSmallScreen ? 15 : 20,
                      right: isSmallScreen ? 15 : 20, // Margin kanan saja
                    ),
                    child: Row(
                      children: [
                        // Box putih - lebar dikurangi dari kanan
                        Container(
                          width: isSmallScreen ? screenSize.width * 0.55 : screenSize.width * 0.6, // Lebar dikurangi
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(25), // Border radius ditambah
                              bottomRight: Radius.circular(25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 3,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: _isLoading 
                            ? Center(
                                child: CircularProgressIndicator(),
                              )
                            : SingleChildScrollView(
                                child: Padding(
                                  padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Main content with horizontal layout exactly like in image
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Left side - Phone Icon (ukuran disesuaikan)
                                          Container(
                                            width: isSmallScreen ? 100 : 120,
                                            height: isSmallScreen ? 150 : 180,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.black,
                                                width: 3,
                                              ),
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Container(
                                              margin: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black,
                                                borderRadius: BorderRadius.circular(11),
                                              ),
                                              child: Column(
                                                children: [
                                                  // Top notch area (more realistic)
                                                  Container(
                                                    height: isSmallScreen ? 12 : 15,
                                                    margin: EdgeInsets.symmetric(
                                                      horizontal: isSmallScreen ? 15 : 18,
                                                      vertical: isSmallScreen ? 3 : 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  // Screen area (more realistic proportions)
                                                  Expanded(
                                                    child: Container(
                                                      margin: EdgeInsets.fromLTRB(4, 0, 4, 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade300,
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(
                                                          color: Colors.grey.shade400,
                                                          width: 1,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          
                                          SizedBox(width: isSmallScreen ? 20 : 30),
                                          
                                          // Right side - All Device Information
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Device Name
                                                Text(
                                                  'Nama Device',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Container(
                                                  height: 1,
                                                  width: double.infinity,
                                                  color: Colors.black,
                                                  margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
                                                ),
                                                Text(
                                                  _deviceName,
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 18,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                
                                                SizedBox(height: isSmallScreen ? 10 : 15),
                                                
                                                // Android Version
                                                Text(
                                                  'Versi Android',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Container(
                                                  height: 1,
                                                  width: double.infinity,
                                                  color: Colors.black,
                                                  margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
                                                ),
                                                Text(
                                                  _androidVersion,
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 18,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                
                                                SizedBox(height: isSmallScreen ? 10 : 15),
                                                
                                                // OS Version
                                                Text(
                                                  'Versi OS',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Container(
                                                  height: 1,
                                                  width: double.infinity,
                                                  color: Colors.black,
                                                  margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
                                                ),
                                                Text(
                                                  _osVersion,
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 18,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                
                                                SizedBox(height: isSmallScreen ? 10 : 15),
                                                
                                                // Android ID with copy button
                                                Text(
                                                  'Android ID',
                                                  style: TextStyle(
                                                    fontSize: isSmallScreen ? 14 : 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                Container(
                                                  height: 1,
                                                  width: double.infinity,
                                                  color: Colors.black,
                                                  margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        _androidId,
                                                        style: TextStyle(
                                                          fontSize: isSmallScreen ? 14 : 18,
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 6),
                                                    GestureDetector(
                                                      onTap: _copyAndroidId,
                                                      child: Container(
                                                        padding: EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey.shade200,
                                                          borderRadius: BorderRadius.circular(4),
                                                          border: Border.all(
                                                            color: Colors.grey.shade400,
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Icon(
                                                          Icons.copy,
                                                          size: isSmallScreen ? 12 : 14,
                                                          color: Colors.grey.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ),
                        
                        // Gap kecil antara box putih dan box biru
                        SizedBox(width: isSmallScreen ? 4 : 6), // Gap dikurangi
                        
                        // Box biru di sebelah kanan dengan celah sedikit
                        Container(
                          width: isSmallScreen ? 30 : 40, // Lebar box biru dikurangi drastis
                          height: isSmallScreen ? 400 : 480, // Tinggi sama dengan box putih
                          decoration: BoxDecoration(
                            color: const Color(0xFFA9D0D7),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(25), // Border radius ditambah
                              bottomRight: Radius.circular(25),
                            ),
                          ),
                        ),
                        
                        // Sisa ruang kosong
                        Expanded(
                          child: Container(), // Kosong
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Area kosong di bawah wrapper
            Expanded(
              child: Container(), // Area kosong untuk background
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 25 : 40, // Padding diperbesar
        vertical: isSmallScreen ? 18 : 25, // Padding diperbesar
      ),
      child: Row(
        children: [
          // Navigation Buttons - Menyatu tanpa gap dengan warna baru
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30), // Border radius diperbesar
              color: const Color(0xFFD9D9D9), // Warna background navbar
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNavButton(
                  title: 'Choose Menu',
                  isActive: false,
                  onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
                  isSmallScreen: isSmallScreen,
                  isFirst: true,
                ),
                _buildNavButton(
                  title: 'Profile Menu',
                  isActive: false,
                  onTap: () => Navigator.of(context).pushReplacementNamed('/profile'),
                  isSmallScreen: isSmallScreen,
                  isMiddle: true,
                ),
                _buildNavButton(
                  title: 'Ponsel Saya',
                  isActive: true,
                  onTap: () {}, // Current page
                  isSmallScreen: isSmallScreen,
                  isLast: true,
                ),
              ],
            ),
          ),
          
          Spacer(),
          
          // Company Logos
          Row(
            children: [
              Image.asset(
                'assets/images/A100.png',
                height: isSmallScreen ? 35 : 45, // Ukuran diperbesar
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isSmallScreen ? 35 : 45,
                    width: isSmallScreen ? 70 : 90,
                    color: Colors.blue,
                    child: const Center(
                      child: Text('ADV', style: TextStyle(color: Colors.white)),
                    ),
                  );
                },
              ),
              SizedBox(width: isSmallScreen ? 10 : 15),
              Image.asset(
                'assets/images/A50.png',
                height: isSmallScreen ? 35 : 45, // Ukuran diperbesar
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isSmallScreen ? 35 : 45,
                    width: isSmallScreen ? 35 : 45,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    required bool isSmallScreen,
    bool isFirst = false,
    bool isMiddle = false,
    bool isLast = false,
  }) {
    BorderRadius borderRadius;
    if (isFirst) {
      borderRadius = BorderRadius.only(
        topLeft: Radius.circular(30), // Border radius diperbesar
        bottomLeft: Radius.circular(30),
      );
    } else if (isLast) {
      borderRadius = BorderRadius.only(
        topRight: Radius.circular(30), // Border radius diperbesar
        bottomRight: Radius.circular(30),
      );
    } else {
      borderRadius = BorderRadius.zero;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 20 : 30, // Padding diperbesar
          vertical: isSmallScreen ? 12 : 16, // Padding diperbesar
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF84DC64) : Colors.transparent, // Warna baru untuk active
          borderRadius: borderRadius,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white,
            fontSize: isSmallScreen ? 14 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomContent(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(
        left: isSmallScreen ? 20 : 30, // Padding internal untuk konten
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'CASH REPLENISH FORM  ver. 0.0.1',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 12 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Image.asset(
                'assets/images/A50.png',
                height: isSmallScreen ? 25 : 35,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: isSmallScreen ? 25 : 35,
                    width: isSmallScreen ? 25 : 35,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              SizedBox(width: isSmallScreen ? 5 : 8),
              Text(
                'CRF',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: isSmallScreen ? 16 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: isSmallScreen ? 2 : 4),
              Text(
                'Cash Replenish Form',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: isSmallScreen ? 10 : 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _noMejaController = TextEditingController();
  String? _selectedBranch;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isLoadingBranches = false;
  List<Map<String, dynamic>> _availableBranches = [];
  String _androidId = 'Loading...'; // Store Android ID
  
  // Auth service
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Set status bar color to match Android theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0056A4),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
    
    // Check if user is already logged in
    _checkLoginStatus();
    
    // Load Android ID
    _loadAndroidId();
    
    // Add listeners to auto-fetch branches when all 3 fields are filled
    _usernameController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _noMejaController.addListener(_onFieldChanged);
  }
  
  // Check login status
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  // Load Android ID
  Future<void> _loadAndroidId() async {
    try {
      // Get AndroidID regardless of platform - no special handling for web
      final deviceId = await DeviceService.getDeviceId();
      setState(() {
        _androidId = deviceId;
      });
    } catch (e) {
      setState(() {
        _androidId = 'Unknown';
      });
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _noMejaController.removeListener(_onFieldChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    _noMejaController.dispose();
    super.dispose();
  }

  // Auto-fetch branches when all 3 fields are filled
  void _onFieldChanged() {
    // Check if all 3 fields have content
    if (_usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _noMejaController.text.isNotEmpty) {
      
      // Reset current branches and selected branch
      if (_availableBranches.isNotEmpty || _selectedBranch != null) {
        setState(() {
          _availableBranches.clear();
          _selectedBranch = null;
        });
      }
      
      // Debounce the API call (wait 500ms after user stops typing)
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_usernameController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _noMejaController.text.isNotEmpty &&
            !_isLoadingBranches) {
          _fetchBranches();
        }
      });
    } else {
      // Clear branches if any field is empty
      if (_availableBranches.isNotEmpty || _selectedBranch != null) {
        setState(() {
          _availableBranches.clear();
          _selectedBranch = null;
        });
      }
    }
  }

  // Fetch available branches
  Future<void> _fetchBranches() async {
    if (_isLoadingBranches) return;
    
    setState(() {
      _isLoadingBranches = true;
    });

    try {
      final result = await _authService.getUserBranches(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        _noMejaController.text.trim(),
      );
      
      if (result['success'] && result['data'] != null) {
        final branches = result['data'] as List<dynamic>;
        
        setState(() {
          _availableBranches = branches.map((branch) => {
            'branchName': branch['branchName'] ?? branch['BranchName'] ?? '',
            'roleID': branch['roleID'] ?? branch['RoleID'] ?? '',
            'displayText': '${branch['branchName'] ?? branch['BranchName'] ?? ''} (${branch['roleID'] ?? branch['RoleID'] ?? ''})',
          }).toList();
          
          // Auto-select if only one branch
          if (_availableBranches.length == 1) {
            _selectedBranch = _availableBranches.first['displayText'];
          }
        });
        
        // Show success feedback
        if (_availableBranches.isNotEmpty) {
          HapticFeedback.lightImpact();
        }
      } else {
        // Clear branches on error but don't show popup yet (user might still be typing)
        setState(() {
          _availableBranches.clear();
          _selectedBranch = null;
        });
      }
    } catch (e) {
      // Clear branches on error
      setState(() {
        _availableBranches.clear();
        _selectedBranch = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBranches = false;
        });
      }
    }
  }

  // Perform login
  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_availableBranches.isEmpty) {
      _showErrorDialog('No Access', 'Please ensure all fields are correct. No CRF branches available for this user.');
      return;
    }
    
    if (_selectedBranch == null && _availableBranches.length > 1) {
      _showErrorDialog('Branch Required', 'Please select a branch to continue.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Extract branch name from selected display text
      String? branchName;
      if (_selectedBranch != null) {
        final selectedBranchData = _availableBranches.firstWhere(
          (branch) => branch['displayText'] == _selectedBranch,
          orElse: () => _availableBranches.first,
        );
        branchName = selectedBranchData['branchName'];
      }

      final result = await _authService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        _noMejaController.text.trim(),
        selectedBranch: branchName,
      );
      
      if (result['success']) {
        // Haptic feedback for Android feel
        HapticFeedback.mediumImpact();
        
        // Navigate to home screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        // Check for AndroidID validation error specifically
        if (result['errorType'] == 'ANDROID_ID_ERROR') {
          _showAndroidIdErrorDialog(result['message'] ?? 'AndroidID belum terdaftar, silahkan hubungi tim COMSEC');
        } else {
          _showErrorDialog('Login Failed', result['message'] ?? 'Invalid credentials');
        }
      }
    } catch (e) {
      _showErrorDialog('Connection Error', 'Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    if (mounted) {
      // Haptic feedback for error
      HapticFeedback.vibrate();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showAndroidIdErrorDialog(String message) {
    if (mounted) {
      // Strong haptic feedback for AndroidID error
      HapticFeedback.heavyImpact();
      
      showDialog(
        context: context,
        barrierDismissible: false, // User must tap OK to dismiss
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.security_outlined,
            size: 48,
            color: Colors.red,
          ),
          title: const Text(
            'AndroidID Tidak Terdaftar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.android, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Android ID Anda:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _androidId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Untuk mendaftarkan AndroidID ini, silahkan hubungi tim COMSEC dengan menyertakan AndroidID di atas.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600; // Threshold for tablet
    
    // Warna biru yang lebih terang untuk button
    final buttonColor = const Color(0xFF2196F3); // Material blue
    
    return Scaffold(
      // Hapus AppBar
      extendBodyBehindAppBar: true,
      body: Container(
        width: size.width,
        height: size.height,
        // Use background image with better fit
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/bg-login.png'),
            fit: BoxFit.cover,
            // Pastikan gambar tidak terpotong dengan alignment yang tepat
            alignment: Alignment.center,
          ),
        ),
        // Use SafeArea to ensure content is visible
        child: SafeArea(
          // Use SingleChildScrollView to handle overflow on smaller screens
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive layout based on screen size
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? size.width * 0.9 : size.width,
                      minHeight: size.height,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? size.width * 0.05 : 16,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Spacer untuk memberikan ruang di atas
                          SizedBox(height: size.height * 0.1),
                          
                          // Logo and form section with responsive width
                          Container(
                            width: isTablet ? size.width * 0.6 : size.width * 0.9,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Login text - responsive
                                Text(
                                  'Login Your Account',
                                  style: TextStyle(
                                    fontSize: isTablet ? 28 : 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0056A4),
                                  ),
                                ),
                                
                                const SizedBox(height: 30),
                                
                                // Form - responsive dengan padding tambahan
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 20.0 : 10.0),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Username/ID/Email/HP
                                        const Text(
                                          'User ID/Email/No.Hp',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        TextFormField(
                                          controller: _usernameController,
                                          decoration: InputDecoration(
                                            hintText: 'Enter your User ID, Email or Phone Number',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                            suffixIcon: const Icon(Icons.person),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your username';
                                            }
                                            return null;
                                          },
                                        ),
                                        
                                        const SizedBox(height: 15),
                                        
                                        // Password
                                        const Text(
                                          'Password',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: !_isPasswordVisible,
                                          decoration: InputDecoration(
                                            hintText: 'Enter your password',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isPasswordVisible = !_isPasswordVisible;
                                                });
                                                // Android haptic feedback
                                                HapticFeedback.lightImpact();
                                              },
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            return null;
                                          },
                                        ),
                                        
                                        const SizedBox(height: 15),
                                        
                                        // No. Meja
                                        const Text(
                                          'No. Meja',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        TextFormField(
                                          controller: _noMejaController,
                                          decoration: InputDecoration(
                                            hintText: 'Enter table number',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                            suffixIcon: const Icon(Icons.table_chart),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter table number';
                                            }
                                            return null;
                                          },
                                        ),
                                        
                                        const SizedBox(height: 15),
                                        
                                        // Branch/Role dropdown (auto-populated)
                                        Row(
                                          children: [
                                            const Text(
                                              'Branch & Role',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (_isLoadingBranches) ...[
                                              const SizedBox(width: 10),
                                              const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        DropdownButtonFormField<String>(
                                          value: _selectedBranch,
                                          decoration: InputDecoration(
                                            hintText: _isLoadingBranches 
                                                ? 'Loading branches...'
                                                : _availableBranches.isEmpty 
                                                    ? 'Fill all fields above to load branches'
                                                    : 'Select branch & role',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            filled: true,
                                            fillColor: _availableBranches.isEmpty ? Colors.grey.shade100 : Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                            suffixIcon: _isLoadingBranches 
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : Icon(
                                                    _availableBranches.isNotEmpty ? Icons.business : Icons.info_outline,
                                                    color: _availableBranches.isNotEmpty ? null : Colors.grey,
                                                  ),
                                          ),
                                          items: _availableBranches.map((branch) {
                                            return DropdownMenuItem<String>(
                                              value: branch['displayText'],
                                              child: Text(
                                                branch['displayText'],
                                                style: const TextStyle(fontSize: 14),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: _availableBranches.isEmpty ? null : (value) {
                                            setState(() {
                                              _selectedBranch = value;
                                            });
                                            // Android haptic feedback
                                            HapticFeedback.selectionClick();
                                          },
                                          validator: (value) {
                                            if (_availableBranches.isEmpty) {
                                              return 'No branches available. Check your credentials.';
                                            }
                                            if (_availableBranches.length > 1 && value == null) {
                                              return 'Please select a branch';
                                            }
                                            return null;
                                          },
                                        ),
                                        
                                        const SizedBox(height: 30),
                                        
                                        // Login button
                                        Center(
                                          child: SizedBox(
                                            width: isTablet ? 250 : 200,
                                            height: isTablet ? 60 : 50,
                                            child: ElevatedButton(
                                              onPressed: (_isLoading || _isLoadingBranches || _availableBranches.isEmpty) 
                                                  ? null 
                                                  : _performLogin,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: buttonColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(25),
                                                ),
                                                elevation: 4,
                                              ),
                                              child: _isLoading
                                                  ? const CircularProgressIndicator(color: Colors.white)
                                                  : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.login, color: Colors.white),
                                                        const SizedBox(width: 10),
                                                        Text(
                                                          'Login',
                                                          style: TextStyle(
                                                            fontSize: isTablet ? 22 : 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Android ID text at bottom with Android icon
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.android, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Android ID : $_androidId',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isTablet ? 16 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Spacer untuk memberikan ruang
                          const SizedBox(height: 20),
                          
                          // Versi aplikasi dengan tulisan kecil di bagian bawah
                          Text(
                            'CRF Android App v1.0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
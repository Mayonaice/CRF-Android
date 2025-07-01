import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import '../services/auth_service.dart';

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
  String? _selectedGroup;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _noMejaController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Use AuthService for login
        final result = await _authService.login(
          _usernameController.text,
          _passwordController.text,
          _noMejaController.text,
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
          if (mounted) {
            // Haptic feedback for error
            HapticFeedback.vibrate();
            
            // Android-style error dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Login Failed'),
                content: Text(result['message'] ?? 'Invalid credentials'),
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
      } catch (e) {
        if (mounted) {
          // Haptic feedback for error
          HapticFeedback.vibrate();
          
          // Android-style error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Connection Error'),
              content: Text('Error: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
                                        
                                        // Group dropdown
                                        const Text(
                                          'Group',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        DropdownButtonFormField<String>(
                                          value: _selectedGroup,
                                          decoration: InputDecoration(
                                            hintText: 'Select group',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Admin',
                                              child: Text('Admin'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'User',
                                              child: Text('User'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Supervisor',
                                              child: Text('Supervisor'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedGroup = value;
                                            });
                                            // Android haptic feedback
                                            HapticFeedback.selectionClick();
                                          },
                                        ),
                                        
                                        const SizedBox(height: 30),
                                        
                                        // Login button - dengan warna biru yang lebih terang
                                        Center(
                                          child: SizedBox(
                                            width: isTablet ? 250 : 200,
                                            height: isTablet ? 60 : 50,
                                            child: ElevatedButton(
                                              onPressed: _isLoading ? null : _login,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.android, color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                'Android ID : 1234Uas61234',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 18 : 16,
                                ),
                              ),
                            ],
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
      // Hapus bottomNavigationBar
    );
  }
} 
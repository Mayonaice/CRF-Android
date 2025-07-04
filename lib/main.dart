import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/prepare_mode_screen.dart';
import 'screens/return_mode_screen.dart';
import 'screens/profile_menu_screen.dart';
import 'screens/device_info_screen.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

// Global error handler
void _handleError(Object error, StackTrace stack) {
  debugPrint('CRITICAL ERROR: $error');
  debugPrintStack(stackTrace: stack);
}

// App-level initialization that happens only once
bool _isAppInitialized = false;

// SafePrefs Class to handle all preference operations safely
class SafePrefs {
  static Future<void> clearAll() async {
    try {
      // Clear preferences if they exist
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('Preferences cleared successfully');
    } catch (e) {
      debugPrint('Failed to clear preferences: $e');
    }
  }
}

class CrfSplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;
  
  const CrfSplashScreen({Key? key, required this.onInitializationComplete}) : super(key: key);

  @override
  State<CrfSplashScreen> createState() => _CrfSplashScreenState();
}

class _CrfSplashScreenState extends State<CrfSplashScreen> {
  String _statusMessage = 'Initializing...';
  bool _hasError = false;
  String _errorDetails = '';
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Add a small delay for UI to render
    await Future.delayed(const Duration(milliseconds: 500));
    
    try {
      // Update status message
      if (mounted) setState(() => _statusMessage = 'Setting up environment...');
      
      // Update status
      if (mounted) setState(() => _statusMessage = 'Setting display orientation...');
      
      // Set orientation - with graceful fallback
      try {
        // Only set orientation on Android
        if (Platform.isAndroid) {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      } catch (e) {
        debugPrint('Failed to set orientation: $e');
      }
      
      // Update status
      if (mounted) setState(() => _statusMessage = 'Configuring UI...');
      
      // Try to set UI style but don't crash if it fails
      try {
        if (Platform.isAndroid) {
          SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            statusBarColor: Color(0xFF0056A4),
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF0056A4),
            systemNavigationBarIconBrightness: Brightness.light,
          ));
        }
      } catch (e) {
        debugPrint('Failed to set system UI style: $e');
      }
      
      // Update status
      if (mounted) setState(() => _statusMessage = 'Initializing data services...');

      // Verify shared preferences access 
      try {
        final prefs = await SharedPreferences.getInstance();
        // Try simple write/read test
        await prefs.setString('_test_key', 'test_value');
        final testValue = prefs.getString('_test_key');
        debugPrint('SharedPreferences test: $testValue');
        await prefs.remove('_test_key');
      } catch (e) {
        debugPrint('SharedPreferences test failed: $e');
        throw Exception('Unable to access app storage: $e');
      }

      // Add a small delay to ensure all async tasks have completed
      await Future.delayed(const Duration(seconds: 1));
      
      // Mark initialization as complete
      _isAppInitialized = true;
      
      // Inform parent that initialization is complete
      if (mounted) {
        widget.onInitializationComplete();
      }
    } catch (error, stack) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorDetails = 'Error: ${error.toString()}\n${stack.toString().split('\n').take(3).join('\n')}';
          _statusMessage = 'Initialization failed';
        });
      }
      _handleError(error, stack);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0056A4),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/bg-login.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Failed to load splash image: $error');
                return const Icon(
                  Icons.account_balance,
                  size: 150,
                  color: Colors.white,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'CRF APP',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            if (_hasError)
              Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorDetails,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Clear data and try again
                      await SafePrefs.clearAll();
                      if (mounted) {
                        setState(() {
                          _hasError = false;
                          _statusMessage = 'Retrying...';
                        });
                        _initializeApp();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0056A4),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> main() async {
  // Ensure proper Flutter binding and handle errors globally
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _handleError(details.exception, details.stack ?? StackTrace.empty);
    };
    
    // Start with splash screen
    runApp(const MyApp());
  }, _handleError);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showMainApp = false;
  
  void _completeInitialization() {
    setState(() {
      _showMainApp = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showMainApp) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: CrfSplashScreen(
          onInitializationComplete: _completeInitialization,
        ),
      );
    }
    
    return MaterialApp(
      title: 'CRF App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Menggunakan tema Android
        platform: TargetPlatform.android,
        // Material 3 untuk tampilan Android modern
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056A4),
          brightness: Brightness.light,
        ),
        // Android-specific theme settings
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0056A4),
          foregroundColor: Colors.white,
          elevation: 4,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Color(0xFF0056A4),
            statusBarIconBrightness: Brightness.light,
          ),
        ),
        // Android button style
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0056A4),
            foregroundColor: Colors.white,
            elevation: 4,
          ),
        ),
      ),
      // Use '/' as initial route to prevent navigation issues
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(), // Default route
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/prepare_mode': (context) => const PrepareModePage(),
        '/return_mode': (context) => const ReturnModePage(),
        '/profile': (context) => const ProfileMenuScreen(),
        '/device_info': (context) => const DeviceInfoScreen(),
      },
      // Global error handling for navigator
      navigatorKey: GlobalKey<NavigatorState>(),
      // Handle errors in the app
      builder: (context, child) {
        // Error handling UI wrapper
        Widget errorScreen(FlutterErrorDetails details) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'An error occurred',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.exception.toString(),
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // Try to restart app to home page
                        Navigator.of(context).pushReplacementNamed('/');
                      },
                      child: const Text('Go to Login'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Set the custom error widget builder
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return errorScreen(errorDetails);
        };
        
        // Return the child or error screen
        return child ?? errorScreen(FlutterErrorDetails(
          exception: 'Failed to build UI',
          library: 'CRF app',
        ));
      },
    );
  }
} 
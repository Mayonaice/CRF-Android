import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/prepare_mode_screen.dart';
import 'dart:async';

// Global error handler
void _handleError(Object error, StackTrace stack) {
  debugPrint('ERROR: $error');
  debugPrintStack(stackTrace: stack);
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
    
    // Try to set orientation but don't crash if it fails
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (e) {
      debugPrint('Failed to set orientation: $e');
    }
    
    // Try to set UI style but don't crash if it fails
    try {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0056A4),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0056A4),
        systemNavigationBarIconBrightness: Brightness.light,
      ));
    } catch (e) {
      debugPrint('Failed to set system UI style: $e');
    }
    
    // Start the app
    runApp(const MyApp());
  }, _handleError);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      'Please restart the application',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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

        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return errorScreen(errorDetails);
        };
        
        return child ?? errorScreen(FlutterErrorDetails(
          exception: 'Unknown error',
        ));
      },
    );
  }
} 
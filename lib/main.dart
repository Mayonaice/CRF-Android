import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/prepare_mode_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Force landscape orientation for Android
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]).then((_) {
    runApp(const MyApp());
  });
  
  // Set Android system UI style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF0056A4),
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0056A4),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
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
          seedColor: Colors.blue,
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
      initialRoute: '/login',
      routes: {
        '/': (context) => const LoginPage(), // Default route
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/prepare_mode': (context) => const PrepareModePage(),
      },
    );
  }
} 
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'device_service.dart';

class AuthService {
  // Make base URL more flexible - allow for fallback
  static const String _primaryBaseUrl = 'http://10.10.0.223/LocalCRF/api';
  static const String _fallbackBaseUrl = 'http://10.10.0.223:8080/LocalCRF/api'; // Fallback URL if primary fails
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String baseUrlKey = 'base_url';
  
  // API timeout duration
  static const Duration _timeout = Duration(seconds: 15);

  // Track which base URL is working
  String _currentBaseUrl = _primaryBaseUrl;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Initialize by loading saved base URL or using primary
    _loadBaseUrl();
  }

  // Platform detection helper
  String _getClientType() {
    if (kIsWeb) {
      // For web platform (Edge testing), return 'WEB' to bypass AndroidID validation
      return 'WEB';
    } else {
      // For mobile platform, return 'Android' 
      return 'Android';
    }
  }

  // Load saved base URL if available
  Future<void> _loadBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentBaseUrl = prefs.getString(baseUrlKey) ?? _primaryBaseUrl;
    } catch (e) {
      debugPrint('Failed to load base URL: $e');
      _currentBaseUrl = _primaryBaseUrl;
    }
  }

  // Save working base URL
  Future<void> _saveBaseUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(baseUrlKey, url);
      _currentBaseUrl = url;
    } catch (e) {
      debugPrint('Failed to save base URL: $e');
    }
  }

  // Try request with fallback if primary fails
  Future<http.Response> _tryRequestWithFallback({
    required Future<http.Response> Function(String baseUrl) requestFn,
  }) async {
    try {
      // Try with current URL
      return await requestFn(_currentBaseUrl).timeout(_timeout);
    } catch (e) {
      debugPrint('Request failed with $_currentBaseUrl: $e');
      
      // Try with fallback URL
      final fallbackUrl = (_currentBaseUrl == _primaryBaseUrl) 
          ? _fallbackBaseUrl 
          : _primaryBaseUrl;
      
      try {
        final response = await requestFn(fallbackUrl).timeout(_timeout);
        
        // If fallback worked, save it as current
        if (response.statusCode >= 200 && response.statusCode < 300) {
          await _saveBaseUrl(fallbackUrl);
        }
        return response;
      } catch (e) {
        debugPrint('Fallback request also failed with $fallbackUrl: $e');
        rethrow;
      }
    }
  }

  // Get available branches for user (Step 1 of 2-step login)
  Future<Map<String, dynamic>> getUserBranches(String username, String password, String noMeja) async {
    try {
      // Get client type and Android ID for device validation
      final clientType = _getClientType();
      final androidId = clientType == 'WEB' ? 'WEB_BYPASS' : await DeviceService.getDeviceId();
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/get-user-branches'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'Username': username,
            'Password': password,
            'NoMeja': noMeja,
            'ClientType': clientType,
            'AndroidId': androidId, // Add Android ID for device validation (or bypass for web)
          }),
        ),
      );

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error parsing JSON: $e');
        return {
          'success': false,
          'message': 'Server returned invalid data: ${response.body.substring(0, min(100, response.body.length))}',
        };
      }
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Branches retrieved successfully',
          'data': responseData['data']
        };
      } else {
        // Check for AndroidID validation error
        if (responseData['message'] != null && 
            responseData['message'].toString().contains('AndroidID belum terdaftar')) {
          return {
            'success': false,
            'message': responseData['message'],
            'errorType': 'ANDROID_ID_ERROR',
            'androidId': androidId,
          };
        }
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get branches (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Get branches error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Login method with enhanced error handling and Android ID check (Step 2 of 2-step login)
  Future<Map<String, dynamic>> login(String username, String password, String noMeja, {String? selectedBranch}) async {
    try {
      // Get client type and Android ID for device validation
      final clientType = _getClientType();
      final androidId = clientType == 'WEB' ? 'WEB_BYPASS' : await DeviceService.getDeviceId();
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'Username': username,
            'Password': password,
            'NoMeja': noMeja,
            'ClientType': clientType,  // Identify this request platform
            'AndroidId': androidId,    // Add Android ID for device validation (or bypass for web)
            if (selectedBranch != null) 'SelectedBranch': selectedBranch,
          }),
        ),
      );

      // Check if we have a valid JSON response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        // Handle invalid JSON
        debugPrint('Error parsing JSON: $e');
        return {
          'success': false,
          'message': 'Server returned invalid data: ${response.body.substring(0, min(100, response.body.length))}',
        };
      }
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Save token and user data
        if (responseData['data'] != null) {
          await saveToken(responseData['data']['token'] ?? '');
          await saveUserData(responseData['data']);
          return {
            'success': true,
            'message': responseData['message'] ?? 'Login successful',
            'data': responseData['data']
          };
        } else {
          return {
            'success': false,
            'message': 'Login successful but no user data returned',
          };
        }
      } else {
        // Check for AndroidID validation error specifically
        if (responseData['message'] != null && 
            (responseData['message'].toString().contains('AndroidID belum terdaftar') ||
             responseData['errorType'] == 'ANDROID_ID_ERROR')) {
          return {
            'success': false,
            'message': 'AndroidID belum terdaftar, silahkan hubungi tim COMSEC',
            'errorType': 'ANDROID_ID_ERROR',
            'androidId': androidId,
          };
        }
        
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Helper to get min value (for string substring)
  int min(int a, int b) {
    return (a < b) ? a : b;
  }

  // Save token to shared preferences
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
    } catch (e) {
      debugPrint('Failed to save token: $e');
    }
  }

  // Get token from shared preferences
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(tokenKey);
    } catch (e) {
      debugPrint('Failed to get token: $e');
      return null;
    }
  }

  // Save user data to shared preferences
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userDataKey, json.encode(userData));
    } catch (e) {
      debugPrint('Failed to save user data: $e');
    }
  }

  // Get user data from shared preferences
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(userDataKey);
      if (userDataString != null && userDataString.isNotEmpty) {
        return json.decode(userDataString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to get user data: $e');
    }
    return null;
  }

  // Logout method
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      await prefs.remove(userDataKey);
    } catch (e) {
      debugPrint('Failed to logout: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('Failed to check login status: $e');
      return false;
    }
  }
} 
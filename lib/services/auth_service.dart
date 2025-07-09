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
    // Always return 'Android' for Flutter app, regardless of platform
    // This ensures we always use CRFAndroid_SP_Login with full validation
    return 'Android';
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
  // No AndroidID validation here - only basic credential check
  Future<Map<String, dynamic>> getUserBranches(String username, String password, String noMeja) async {
    try {
      // Get client type but don't send AndroidID for branches check
      final clientType = _getClientType();
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/get-user-branches'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'Username': username,
            'Password': password,
            'NoMeja': noMeja,
            'ClientType': clientType,
            // No AndroidId parameter - skip AndroidID validation for branches
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
      var androidId = await DeviceService.getDeviceId();
      
      // If androidId is error_unknown_device, use test device ID
      if (androidId == 'error_unknown_device' || androidId.isEmpty) {
        androidId = '1234567fortest89';
        debugPrint('Using test device ID: $androidId');
      }
      
      print('🚀 DEBUG LOGIN: username=$username, noMeja=$noMeja');
      print('🚀 DEBUG LOGIN: clientType=$clientType');
      print('🚀 DEBUG LOGIN: androidId=$androidId');
      print('🚀 DEBUG LOGIN: selectedBranch=$selectedBranch');
      print('🚀 DEBUG LOGIN: baseUrl=$_currentBaseUrl');
      
      final requestBody = {
        'Username': username,
        'Password': password,
        'NoMeja': noMeja,
        'ClientType': clientType,
        'AndroidId': androidId,
        if (selectedBranch != null) 'SelectedBranch': selectedBranch,
      };
      
      print('🚀 DEBUG LOGIN: Request body = ${json.encode(requestBody)}');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        ),
      );

      print('🚀 DEBUG LOGIN: Response status = ${response.statusCode}');
      print('🚀 DEBUG LOGIN: Response body = ${response.body}');

      // Check if we have a valid JSON response
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
        print('🚀 DEBUG LOGIN: SUCCESS!');
        // Save token and user data
        if (responseData['data'] != null) {
          // Tambahkan branchCode jika belum ada
          if (!responseData['data'].containsKey('branchCode') && selectedBranch != null) {
            responseData['data']['branchCode'] = selectedBranch;
          }
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
        print('🚀 DEBUG LOGIN: FAILED - ${responseData['message']}');
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
      print('🚀 DEBUG LOGIN: EXCEPTION = $e');
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }

  // Login directly with token for test mode
  Future<Map<String, dynamic>> loginWithToken(String token) async {
    try {
      // Verify token by making a test request
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.get(
          Uri.parse('$baseUrl/CRF/check-session'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Save the token
          await saveToken(token);
          
          // Extract user data from token
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = json.decode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
            );
            
            // Create user data from token claims
            final userData = {
              'token': token,
              'userId': payload['userId'] ?? '',
              'userName': payload['sub'] ?? '',
              'role': payload['role'] ?? '',
              'isTestMode': true,
            };
            
            await saveUserData(userData);
            
            return {
              'success': true,
              'message': 'Login berhasil (Test Mode)',
              'data': userData
            };
          }
        }
      }
      
      return {
        'success': false,
        'message': 'Token tidak valid',
      };
    } catch (e) {
      debugPrint('Error logging in with token: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
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

  // Add token expiration check
  Future<bool> shouldRefreshToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;
      
      // Parse JWT token
      final parts = token.split('.');
      if (parts.length != 3) return false;

      // Decode payload
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
      );
      
      // Get expiration timestamp
      final expiration = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      
      // Refresh if less than 1 hour remaining
      final shouldRefresh = DateTime.now().isAfter(expiration.subtract(Duration(hours: 1)));
      debugPrint('Token expires at: $expiration, shouldRefresh: $shouldRefresh');
      return shouldRefresh;
    } catch (e) {
      debugPrint('Error checking token expiration: $e');
      return false;
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      debugPrint('Attempting to refresh token');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/refresh-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
        ),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('Refresh token response: ${response.body}');
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final newToken = responseData['data']['token'];
          await saveToken(newToken);
          debugPrint('Token refreshed successfully');
          return true;
        }
      }
      
      debugPrint('Failed to refresh token: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

  // Check if user is in test mode
  Future<bool> isTestMode() async {
    try {
      final userData = await getUserData();
      if (userData == null) return false;
      
      final username = userData['userName'] as String?;
      if (username == null) return false;
      
      return username.toLowerCase().startsWith('test_') || 
             username.toLowerCase().endsWith('_test');
    } catch (e) {
      debugPrint('Error checking test mode: $e');
      return false;
    }
  }
} 
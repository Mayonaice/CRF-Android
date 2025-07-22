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

  // Enhanced login method with role-based authentication
  Future<Map<String, dynamic>> login(String username, String password, String noMeja, {String? selectedBranch}) async {
    try {
      // Get device ID for validation
      final deviceId = await DeviceService.getDeviceId();
      
      // Get client type
      final clientType = _getClientType();
      
      debugPrint('Login attempt for user: $username, deviceId: $deviceId, selectedBranch: $selectedBranch');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'username': username,
            'password': password,
            'noMeja': noMeja,
            'androidId': deviceId,
            'clientType': clientType,
            'selectedBranch': selectedBranch
          }),
        ),
      );
      
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      // Check for API error
      if (responseData['success'] != true) {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Unknown error',
          'errorType': (responseData['message'] ?? '').toString().contains('AndroidID') 
              ? 'ANDROID_ID_ERROR' 
              : 'LOGIN_ERROR'
        };
      }
      
      // Store token - Check if token exists in response
      if (responseData['data'] == null || responseData['data']['token'] == null) {
        debugPrint('ERROR: Login response missing token data!');
        debugPrint('Response data: ${json.encode(responseData)}');
        return {
          'success': false,
          'message': 'Server error: Login response missing token',
          'errorType': 'TOKEN_MISSING'
        };
      }
      
      final token = responseData['data']['token'];
      if (token == null || token.isEmpty) {
        debugPrint('ERROR: Token is null or empty!');
        return {
          'success': false,
          'message': 'Server error: Token is empty',
          'errorType': 'TOKEN_EMPTY'
        };
      }
      
      // Print token for debugging (partial for security)
      final displayToken = token.length > 10 ? "${token.substring(0, 5)}...${token.substring(token.length - 5)}" : token;
      debugPrint('Token received: $displayToken (length: ${token.length})');
      
      // Store token with verification
      final tokenStored = await saveToken(token);
      if (!tokenStored) {
        debugPrint('ERROR: Failed to store token!');
        return {
          'success': false,
          'message': 'Error storing token',
          'errorType': 'TOKEN_STORAGE_ERROR'
        };
      }
      
      // Store user data
      Map<String, dynamic> userData = responseData['data'];
      // Ensure branchCode is included
      if (selectedBranch != null && !userData.containsKey('branchCode')) {
        userData['branchCode'] = selectedBranch;
      }
      await saveUserData(userData);
      
      // Double-check token storage by reading it back immediately
      final storedToken = await getToken();
      if (storedToken == null || storedToken.isEmpty) {
        debugPrint('WARNING: Token storage verification failed! Stored token is null or empty.');
        
        // Try one more time with a slight delay
        await Future.delayed(Duration(milliseconds: 100));
        final retryToken = await getToken();
        if (retryToken == null || retryToken.isEmpty) {
          debugPrint('ERROR: Token storage retry failed! Token still null or empty.');
          return {
            'success': false,
            'message': 'Error retrieving stored token',
            'errorType': 'TOKEN_RETRIEVAL_ERROR'
          };
        }
      } else {
        debugPrint('Token storage verification successful');
      }
      
      return {
        'success': true,
        'message': 'Login successful',
        'role': responseData['data']['role']
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
        'errorType': 'CONNECTION_ERROR'
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
  Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Validate token
      if (token.isEmpty) {
        debugPrint('WARNING: Attempting to save empty token!');
        return false;
      }
      
      // Clear token first to ensure clean state
      await prefs.remove(tokenKey);
      
      // Store token
      final success = await prefs.setString(tokenKey, token);
      
      if (!success) {
        debugPrint('WARNING: Failed to save token to SharedPreferences!');
        return false;
      } else {
        debugPrint('Token saved successfully (length: ${token.length})');
        return true;
      }
    } catch (e) {
      debugPrint('Error saving token: $e');
      return false;
    }
  }
  
  // Get token from shared preferences
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(tokenKey);
      
      // Log token details for debugging (partial token for security)
      if (token != null && token.isNotEmpty) {
        final parts = token.split('.');
        final displayPart = token.length > 10 ? "${token.substring(0, 5)}...${token.substring(token.length - 5)}" : token;
        debugPrint('Retrieved token: $displayPart (length: ${token.length}, parts: ${parts.length})');
      } else {
        debugPrint('Retrieved token is null or empty');
      }
      
      return token;
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }
  
  // Forcefully reset token (for testing)
  Future<void> resetToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
      debugPrint('Token forcefully reset');
    } catch (e) {
      debugPrint('Error resetting token: $e');
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

      try {
        // Decode payload
        final payload = json.decode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))
        );
        
        // Get expiration timestamp
        if (!payload.containsKey('exp')) {
          debugPrint('Token does not contain expiration claim');
          return false; // Don't refresh if no expiration found - API will handle it
        }
        
        final expiration = DateTime.fromMillisecondsSinceEpoch((payload['exp'] as int) * 1000);
        
        // Only refresh if token is actually expired
        final isExpired = DateTime.now().isAfter(expiration);
        debugPrint('Token expires at: $expiration, isExpired: $isExpired');
        return isExpired;
      } catch (parseError) {
        debugPrint('Error parsing token payload: $parseError');
        return false; // Don't refresh if parsing fails - API will handle it
      }
    } catch (e) {
      debugPrint('Error checking token expiration: $e');
      return false; // Don't refresh if any error occurs - API will handle it
    }
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      debugPrint('Attempting to refresh token');
      
      // Try primary URL first
      try {
        final response = await http.post(
          Uri.parse('$_primaryBaseUrl/CRF/refresh-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
        ).timeout(Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          debugPrint('Refresh token response: ${response.body}');
          
          if (responseData['success'] == true && responseData['data'] != null && 
              responseData['data']['token'] != null) {
            final newToken = responseData['data']['token'];
            await saveToken(newToken);
            debugPrint('Token refreshed successfully');
            return true;
          }
        } else {
          debugPrint('Failed to refresh token with primary URL: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error refreshing token with primary URL: $e');
      }
      
      // Try fallback URL if primary fails
      try {
        final response = await http.post(
          Uri.parse('$_fallbackBaseUrl/CRF/refresh-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token'
          },
        ).timeout(Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          debugPrint('Refresh token response (fallback): ${response.body}');
          
          if (responseData['success'] == true && responseData['data'] != null && 
              responseData['data']['token'] != null) {
            final newToken = responseData['data']['token'];
            await saveToken(newToken);
            debugPrint('Token refreshed successfully with fallback URL');
            return true;
          }
        }
      } catch (e) {
        debugPrint('Error refreshing token with fallback URL: $e');
      }
      
      // If we get here, both attempts failed
      debugPrint('Failed to refresh token with both URLs');
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

  // Get user role from stored data with priority to roleID
  Future<String?> getUserRole() async {
    try {
      final userData = await getUserData();
      if (userData == null) return null;
      
      // Print all possible role fields for debugging
      print('DEBUG getUserRole: roleID=${userData['roleID']}, role=${userData['role']}');
      
      // Prioritize roleID field as it's the field name from API
      String? userRole = (userData['roleID'] ?? 
                        userData['RoleID'] ?? 
                        userData['role'] ?? 
                        userData['Role'] ?? 
                        userData['userRole'] ?? 
                        userData['UserRole'] ?? 
                        userData['position'] ?? 
                        userData['Position'])?.toString();
                        
      print('DEBUG getUserRole: normalized userRole=$userRole');
      return userRole?.toUpperCase();
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  // Check if user has specific role (using uppercase for consistency)
  Future<bool> hasRole(String requiredRole) async {
    try {
      final userRole = await getUserRole();
      if (userRole == null) return false;
      
      // Normalize role comparison using uppercase
      print('DEBUG hasRole: comparing userRole=$userRole with requiredRole=$requiredRole');
      return userRole.toUpperCase() == requiredRole.toUpperCase();
    } catch (e) {
      debugPrint('Error checking user role: $e');
      return false;
    }
  }

  // Check if user has any of the specified roles (using uppercase for consistency)
  Future<bool> hasAnyRole(List<String> requiredRoles) async {
    try {
      final userRole = await getUserRole();
      if (userRole == null) return false;
      
      // Normalize and check against all required roles using uppercase
      final normalizedUserRole = userRole.toUpperCase();
      print('DEBUG hasAnyRole: checking userRole=$normalizedUserRole against requiredRoles=$requiredRoles');
      return requiredRoles.any((role) => role.toUpperCase() == normalizedUserRole);
    } catch (e) {
      debugPrint('Error checking user roles: $e');
      return false;
    }
  }

  // Get available menu items based on user role (using uppercase for consistency)
  Future<List<String>> getAvailableMenus() async {
    try {
      final userRole = await getUserRole();
      print('DEBUG getAvailableMenus: userRole=$userRole');
      if (userRole == null) return [];
      
      switch (userRole.toUpperCase()) {
        case 'CRF_KONSOL':
          return [
            'prepare_mode',
            'return_mode',
            'device_info',
            'settings_opr',
            'konsol_mode', // Added Konsol Mode menu
          ];
        case 'CRF_TL':
          print('DEBUG: Returning menus for CRF_TL role');
          return [
            'dashboard_tl',
            'team_management',
            'approvals',
            'reports_tl',
            'settings_tl',
          ];
        case 'CRF_OPR':
        default:
          return [
            'prepare_mode',
            'return_mode',
            'device_info',
            'settings_opr',
          ];
      }
    } catch (e) {
      debugPrint('Error getting available menus: $e');
      return [];
    }
  }
} 
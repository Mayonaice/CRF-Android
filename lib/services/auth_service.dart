import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String baseUrl = 'http://10.10.0.223/LocalCRF/api';
  static const String tokenKey = 'auth_token';
  static const String userDataKey = 'user_data';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Login method
  Future<Map<String, dynamic>> login(String username, String password, String noMeja) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/CRF/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'Username': username,
          'Password': password,
          'NoMeja': noMeja
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Save token and user data
        await saveToken(responseData['data']['token']);
        await saveUserData(responseData['data']);
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data']
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error connecting to server: $e',
      };
    }
  }

  // Save token to shared preferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Get token from shared preferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Save user data to shared preferences
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userDataKey, json.encode(userData));
  }

  // Get user data from shared preferences
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(userDataKey);
    if (userDataString != null) {
      return json.decode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }

  // Logout method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userDataKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
} 
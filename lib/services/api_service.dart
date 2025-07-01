import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/prepare_model.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Use the same base URL handling as AuthService
  static const String _primaryBaseUrl = 'http://10.10.0.223/LocalCRF/api';
  static const String _fallbackBaseUrl = 'http://10.10.0.223:8080/LocalCRF/api';
  
  // API timeout duration
  static const Duration _timeout = Duration(seconds: 15);

  // Track which base URL is working
  String _currentBaseUrl = _primaryBaseUrl;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  // Auth service
  final AuthService _authService = AuthService();

  ApiService._internal();

  // Get headers for API requests with authorization token
  Future<Map<String, String>> get headers async {
    try {
      final token = await _authService.getToken();
      
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': token != null ? 'Bearer $token' : '',
      };
    } catch (e) {
      debugPrint('Error getting headers: $e');
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }
  }

  // Try request with fallback
  Future<http.Response> _tryRequestWithFallback({
    required Future<http.Response> Function(String baseUrl) requestFn,
  }) async {
    try {
      // Try with primary URL first
      return await requestFn(_primaryBaseUrl).timeout(_timeout);
    } catch (e) {
      debugPrint('Request failed with $_primaryBaseUrl: $e');
      
      // Try with fallback URL
      try {
        final response = await requestFn(_fallbackBaseUrl).timeout(_timeout);
        return response;
      } catch (e) {
        debugPrint('Fallback request also failed: $e');
        rethrow;
      }
    }
  }

  // Get ATM Prepare Replenish data by ID with better error handling
  Future<PrepareReplenishResponse> getATMPrepareReplenish(int id) async {
    try {
      final requestHeaders = await headers;
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.get(
          Uri.parse('$baseUrl/CRF/atm/prepare-replenish/$id'),
          headers: requestHeaders,
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return PrepareReplenishResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing JSON: $e');
          throw Exception('Invalid data format from server');
        }
      } else if (response.statusCode == 401) {
        // Handle auth error - try to clear token and redirect to login
        await _authService.logout();
        throw Exception('Session expired: Please login again');
      } else {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('API error: $e');
      if (e is TimeoutException) {
        throw Exception('Connection timeout: Please check your internet connection');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
} 
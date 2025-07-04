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

  // Get Catridge details by code with standValue validation
  Future<CatridgeResponse> getCatridgeDetails(String branchCode, String catridgeCode, {int? requiredStandValue}) async {
    try {
      final requestHeaders = await headers;
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) {
          // Build URL with query parameters
          String url = '$baseUrl/CRF/catridge/list?branchCode=$branchCode&catridgeCode=$catridgeCode';
          if (requiredStandValue != null) {
            url += '&requiredStandValue=$requiredStandValue';
          }
          
          print('Catridge lookup URL: $url');
          return http.get(
            Uri.parse(url),
            headers: requestHeaders,
          );
        },
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('Raw API Response: ${response.body}');
          print('Parsed JSON: $jsonData');
          final catridgeResponse = CatridgeResponse.fromJson(jsonData);
          print('CatridgeResponse data count: ${catridgeResponse.data.length}');
          if (catridgeResponse.data.isNotEmpty) {
            print('First catridge standValue: ${catridgeResponse.data.first.standValue}');
          } else {
            print('No catridge found - likely failed exact match or standValue validation');
          }
          return catridgeResponse;
        } catch (e) {
          debugPrint('Error parsing catridge JSON: $e');
          throw Exception('Invalid catridge data format from server');
        }
      } else if (response.statusCode == 401) {
        // Handle auth error - try to clear token and redirect to login
        await _authService.logout();
        throw Exception('Session expired: Please login again');
      } else {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Catridge API error: $e');
      if (e is TimeoutException) {
        throw Exception('Connection timeout: Please check your internet connection');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Validate Seal Code - Comprehensive validation using new SP with old endpoint
  Future<SealValidationResponse> validateSeal(String sealCode) async {
    try {
      final requestHeaders = await headers;
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.get(
          Uri.parse('$baseUrl/CRF/validate/seal/$sealCode'),
          headers: requestHeaders,
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          debugPrint('Seal validation response: ${response.body}');
          return SealValidationResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing seal validation JSON: $e');
          throw Exception('Invalid seal validation data format from server');
        }
      } else if (response.statusCode == 401) {
        // Handle auth error - try to clear token and redirect to login
        await _authService.logout();
        throw Exception('Session expired: Please login again');
      } else {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Seal validation API error: $e');
      if (e is TimeoutException) {
        throw Exception('Connection timeout: Please check your internet connection');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Update Planning API for TL Supervisor approval
  Future<ApiResponse> updatePlanning({
    required int idTool,
    required String cashierCode,
    required String spvTLCode,
    required String tableCode,
    String warehouseCode = "Cideng",
  }) async {
    try {
      final requestHeaders = await headers;
      
      final requestBody = {
        "IdTool": idTool,
        "CashierCode": cashierCode,
        "CashierCode2": "", // Kosongkan sesuai requirement
        "TableCode": tableCode,
        "DateStart": DateTime.now().toIso8601String(),
        "WarehouseCode": warehouseCode,
        "SpvTLCode": spvTLCode,
        "IsManual": "N"
      };
      
      print('Planning update request: ${json.encode(requestBody)}');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/planning/update'),
          headers: requestHeaders,
          body: json.encode(requestBody),
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('Planning update response: ${response.body}');
          return ApiResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing planning update JSON: $e');
          throw Exception('Invalid planning update data format from server');
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired: Please login again');
      } else {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('Planning update API error: $e');
      if (e is TimeoutException) {
        throw Exception('Connection timeout: Please check your internet connection');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Insert ATM Catridge API
  Future<ApiResponse> insertAtmCatridge({
    required int idTool,
    required String bagCode,
    required String catridgeCode,
    required String sealCode,
    required String catridgeSeal,
    required String denomCode,
    required String qty,
    required String userInput,
    required String sealReturn,
    String scanCatStatus = "TEST",
    String scanCatStatusRemark = "TEST",
    String scanSealStatus = "TEST",
    String scanSealStatusRemark = "TEST",
    String difCatAlasan = "TEST",
    String difCatRemark = "TEST",
  }) async {
    try {
      final requestHeaders = await headers;
      
      final requestBody = {
        "IdTool": idTool,
        "BagCode": bagCode,
        "CatridgeCode": catridgeCode,
        "SealCode": sealCode,
        "CatridgeSeal": catridgeSeal,
        "DenomCode": denomCode,
        "Qty": qty,
        "UserInput": userInput,
        "SealReturn": sealReturn,
        "ScanCatStatus": scanCatStatus,
        "ScanCatStatusRemark": scanCatStatusRemark,
        "ScanSealStatus": scanSealStatus,
        "ScanSealStatusRemark": scanSealStatusRemark,
        "DifCatAlasan": difCatAlasan,
        "DifCatRemark": difCatRemark,
      };
      
      print('ATM Catridge insert request: ${json.encode(requestBody)}');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/atm/catridge'),
          headers: requestHeaders,
          body: json.encode(requestBody),
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('ATM Catridge insert response: ${response.body}');
          return ApiResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing ATM catridge insert JSON: $e');
          throw Exception('Invalid ATM catridge insert data format from server');
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired: Please login again');
      } else {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('ATM Catridge insert API error: $e');
      if (e is TimeoutException) {
        throw Exception('Connection timeout: Please check your internet connection');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }
} 
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/prepare_model.dart';
import '../models/return_model.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Gunakan base URL yang benar sesuai backend
  static const String _primaryBaseUrl = 'http://10.10.0.223/LocalCRF/api';
  // Hapus fallback ke port 8080 karena backend hanya di /LocalCRF/
  static const String _fallbackBaseUrl = 'http://10.10.0.223/LocalCRF/api';
  
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

  // Save working base URL
  Future<void> _saveBaseUrl(String url) async {
    try {
      _currentBaseUrl = url;
      debugPrint('Switching to base URL: $url');
    } catch (e) {
      debugPrint('Failed to save base URL: $e');
    }
  }

  // Try request with fallback
  Future<http.Response> _tryRequestWithFallback({
    required Future<http.Response> Function(String baseUrl) requestFn,
  }) async {
    try {
      // Try with current URL
      final response = await requestFn(_currentBaseUrl).timeout(_timeout);
      
      // Check for auth errors
      if (response.statusCode == 401) {
        // Let auth service handle token refresh
        throw Exception('Session expired: Please login again');
      }
      
      return response;
    } catch (e) {
      debugPrint('Request failed with $_currentBaseUrl: $e');
      
      // Try with fallback URL
      final fallbackUrl = (_currentBaseUrl == _primaryBaseUrl) 
          ? _fallbackBaseUrl 
          : _primaryBaseUrl;
      
      try {
        final response = await requestFn(fallbackUrl).timeout(_timeout);
        
        // Check for auth errors on fallback
        if (response.statusCode == 401) {
          throw Exception('Session expired: Please login again');
        }
        
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

  // Get Return Catridge data by ID
  Future<ReturnCatridgeResponse> getReturnCatridge(String idTool, {String branchCode = "0"}) async {
    try {
      final requestHeaders = await headers;
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.get(
          Uri.parse('$baseUrl/CRF/atm/return-catridge/$idTool?branchCode=$branchCode'),
          headers: requestHeaders,
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return ReturnCatridgeResponse.fromJson(jsonData);
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

  // Insert Return ATM Catridge
  Future<ApiResponse> insertReturnAtmCatridge({
    required String idTool,
    required String bagCode,
    required String catridgeCode,
    required String sealCode,
    required String catridgeSeal,
    required String denomCode,
    required String qty,
    required String userInput,
    String isBalikKaset = "N",
    String catridgeCodeOld = "",
    String scanCatStatus = "TEST",
    String scanCatStatusRemark = "TEST",
    String scanSealStatus = "TEST",
    String scanSealStatusRemark = "TEST",
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
        "IsBalikKaset": isBalikKaset,
        "CatridgeCodeOld": catridgeCodeOld,
        "ScanCatStatus": scanCatStatus,
        "ScanCatStatusRemark": scanCatStatusRemark,
        "ScanSealStatus": scanSealStatus,
        "ScanSealStatusRemark": scanSealStatusRemark,
      };
      
      print('Return ATM Catridge insert request: ${json.encode(requestBody)}');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/rtn/atm/catridge'),
          headers: requestHeaders,
          body: json.encode(requestBody),
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('Return ATM Catridge insert response: ${response.body}');
          return ApiResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing Return ATM catridge insert JSON: $e');
          return ApiResponse(
            success: false,
            message: 'Invalid Return ATM catridge insert data format from server',
            status: 'error'
          );
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        return ApiResponse(
          success: false,
          message: 'Session expired: Please login again',
          status: 'error'
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Server error (${response.statusCode}): ${response.body}',
          status: 'error'
        );
      }
    } catch (e) {
      debugPrint('Return ATM Catridge insert API error: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        status: 'error'
      );
    }
  }

  // Get Catridge details by code with standValue and type validation
  Future<CatridgeResponse> getCatridgeDetails(
    String branchCode, 
    String catridgeCode, {
    int? requiredStandValue,
    String? requiredType,
    List<String>? existingCatridges,
  }) async {
    try {
      final requestHeaders = await headers;
      
      // Check for duplicate catridge
      if (existingCatridges != null && existingCatridges.contains(catridgeCode)) {
        return CatridgeResponse(
          success: false,
          message: 'Catridge sudah digunakan di section lain',
          data: [],
          errorType: 'DUPLICATE_CATRIDGE'
        );
      }
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) {
          // Build URL with query parameters
          String url = '$baseUrl/CRF/catridge/list?branchCode=$branchCode&catridgeCode=$catridgeCode';
          if (requiredStandValue != null) {
            url += '&requiredStandValue=$requiredStandValue';
          }
          if (requiredType != null) {
            url += '&requiredType=$requiredType';
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
          
          // Log error type jika ada
          if (!catridgeResponse.success && catridgeResponse.errorType != null) {
            print('Catridge error type: ${catridgeResponse.errorType}');
          }
          
          print('CatridgeResponse data count: ${catridgeResponse.data.length}');
          if (catridgeResponse.data.isNotEmpty) {
            print('First catridge standValue: ${catridgeResponse.data.first.standValue}');
            print('First catridge type: ${catridgeResponse.data.first.typeCatridge}');
          } else {
            print('No catridge found - ${catridgeResponse.errorType ?? "unknown error"}');
          }
          return catridgeResponse;
        } catch (e) {
          debugPrint('Error parsing catridge JSON: $e');
          return CatridgeResponse(
            success: false,
            message: 'Invalid catridge data format from server',
            data: [],
            errorType: 'PARSE_ERROR'
          );
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        return CatridgeResponse(
          success: false,
          message: 'Session expired: Please login again',
          data: [],
          errorType: 'AUTH_ERROR'
        );
      } else {
        return CatridgeResponse(
          success: false,
          message: 'Server error (${response.statusCode}): ${response.body}',
          data: [],
          errorType: 'SERVER_ERROR'
        );
      }
    } catch (e) {
      debugPrint('Catridge API error: $e');
      String errorType = 'NETWORK_ERROR';
      String message = 'Network error';
      
      if (e is TimeoutException) {
        errorType = 'TIMEOUT_ERROR';
        message = 'Connection timeout: Please check your internet connection';
      }
      
      return CatridgeResponse(
        success: false,
        message: message,
        data: [],
        errorType: errorType
      );
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
    String difCatAlasan = "",
    String difCatRemark = "",
    String typeCatridgeTrx = "C", // Default to 'C' for backward compatibility
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
        "TypeCatridgeTrx": typeCatridgeTrx,
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
          
          // Handle both API controller response and direct SP response
          final apiResponse = ApiResponse.fromJson(jsonData);
          
          // Log response details
          print('Insert response: success=${apiResponse.success}, message=${apiResponse.message}, insertedId=${apiResponse.insertedId}');
          
          return apiResponse;
        } catch (e) {
          debugPrint('Error parsing ATM catridge insert JSON: $e');
          return ApiResponse(
            success: false,
            message: 'Invalid ATM catridge insert data format from server',
            status: 'error'
          );
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        return ApiResponse(
          success: false,
          message: 'Session expired: Please login again',
          status: 'error'
        );
      } else {
        return ApiResponse(
          success: false,
          message: 'Server error (${response.statusCode}): ${response.body}',
          status: 'error'
        );
      }
    } catch (e) {
      debugPrint('ATM Catridge insert API error: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        status: 'error'
      );
    }
  }

  // Validate TL Supervisor for approval
  Future<TLSupervisorValidationResponse> validateTLSupervisor({
    required String nik,
    required String password,
  }) async {
    try {
      final requestHeaders = await headers;
      
      final requestBody = {
        "NIK": nik,
        "Password": password,
      };
      
      print('TL Supervisor validation request: ${json.encode(requestBody)}');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/validate/tl-supervisor'),
          headers: requestHeaders,
          body: json.encode(requestBody),
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('TL Supervisor validation response: ${response.body}');
          return TLSupervisorValidationResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing TL supervisor validation JSON: $e');
          throw Exception('Invalid TL supervisor validation data format from server');
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        throw Exception('Session expired: Please login again');
      } else {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('TL Supervisor validation API error: $e');
      if (e is TimeoutException) {
        throw Exception('Connection timeout: Please check your internet connection');
      }
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get Return Header and Catridge data by ID
  Future<ReturnHeaderResponse> getReturnHeaderAndCatridge(String idCrf, {required String branchCode}) async {
    try {
      final requestHeaders = await headers;
      
      // Gunakan endpoint yang benar sesuai route di backend
      final url = '$_currentBaseUrl/api/CRF/return/header-and-catridge/$idCrf?branchCode=$branchCode';
      print('Return URL: $url');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.get(
          Uri.parse('$baseUrl/api/CRF/return/header-and-catridge/$idCrf?branchCode=$branchCode'),
          headers: requestHeaders,
        ),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return ReturnHeaderResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing JSON: $e');
          throw Exception('Invalid data format from server');
        }
      } else if (response.statusCode == 401) {
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
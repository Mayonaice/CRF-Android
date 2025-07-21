import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/prepare_model.dart';
import '../models/return_model.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

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
    // Track the current attempt for detailed error reporting
    String currentAttemptUrl = _currentBaseUrl;
    String errorDetails = '';
    
    try {
      // Try with current URL
      debugPrint('Attempting request with primary URL: $currentAttemptUrl');
      final response = await requestFn(_currentBaseUrl).timeout(_timeout);
      
      // Check for auth errors
      if (response.statusCode == 401) {
        // Let auth service handle token refresh
        debugPrint('Authentication error (401) with URL: $currentAttemptUrl');
        throw Exception('Session expired: Please login again');
      }
      
      debugPrint('Request successful with URL: $currentAttemptUrl, Status: ${response.statusCode}');
      return response;
    } catch (e) {
      errorDetails = 'Request failed with $currentAttemptUrl: $e';
      debugPrint(errorDetails);
      
      // Try with fallback URL
      final fallbackUrl = (_currentBaseUrl == _primaryBaseUrl) 
          ? _fallbackBaseUrl 
          : _primaryBaseUrl;
      
      currentAttemptUrl = fallbackUrl; // Update for error reporting
      
      try {
        debugPrint('Attempting request with fallback URL: $fallbackUrl');
        final response = await requestFn(fallbackUrl).timeout(_timeout);
        
        // Check for auth errors on fallback
        if (response.statusCode == 401) {
          debugPrint('Authentication error (401) with fallback URL: $fallbackUrl');
          throw Exception('Session expired: Please login again');
        }
        
        // If fallback worked, save it as current
        if (response.statusCode >= 200 && response.statusCode < 300) {
          await _saveBaseUrl(fallbackUrl);
          debugPrint('Fallback request successful, switching to URL: $fallbackUrl');
        } else {
          debugPrint('Fallback request completed with status: ${response.statusCode}');
        }
        return response;
      } catch (e2) {
        final fallbackErrorDetails = 'Fallback request also failed with $fallbackUrl: $e2';
        debugPrint(fallbackErrorDetails);
        
        // Provide detailed error message combining both attempts
        throw Exception('Kedua URL server tidak dapat diakses.\n\nURL Utama: $_primaryBaseUrl\nKesalahan: $e\n\nURL Cadangan: $_fallbackBaseUrl\nKesalahan: $e2\n\nMohon periksa koneksi internet dan konfigurasi server.');
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
      
      // Convert idTool to integer if possible
      int? idToolNum;
      try {
        idToolNum = int.parse(idTool);
      } catch (e) {
        debugPrint('Error converting idTool to int: $e');
        idToolNum = 0;
      }
      
      final requestBody = {
        "IdTool": idToolNum > 0 ? idToolNum : idTool,
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
        "ScanSealStatusRemark": scanSealStatusRemark
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
          
          // Check if the response contains direct success/status fields from SP
          if (jsonData.containsKey('data')) {
            try {
              final dataObject = jsonData['data'];
              if (dataObject is String) {
                final dataJson = json.decode(dataObject);
                if (dataJson is List && dataJson.isNotEmpty) {
                  final status = dataJson[0]['Status']?.toString().toLowerCase();
                  final message = dataJson[0]['Message']?.toString();
                  
                  if (status != null && status != 'success') {
                    return ApiResponse(
                      success: false,
                      message: message ?? 'Gagal menyimpan data catridge return',
                      status: 'error'
                    );
                  }
                }
              }
            } catch (e) {
              debugPrint('Error parsing inner data JSON: $e');
            }
          }
          
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

  // Get catridge details with retry for different formats
  Future<ApiResponse> getCatridgeDetails(
    String branchCode, 
    String catridgeCode, {
    int? requiredStandValue,
    String? requiredType,
    List<String>? existingCatridges,
  }) async {
    try {
      final requestHeaders = await headers;
      
      // Try with original format first
      final originalResponse = await _tryCatridgeFormat(
        branchCode, 
        catridgeCode.trim(), 
        requestHeaders,
        requiredStandValue: requiredStandValue,
        requiredType: requiredType,
        existingCatridges: existingCatridges,
      );
      
      if (originalResponse.success) {
        return originalResponse;
      }
      
      // If original format fails, try without spaces
      final noSpacesCode = catridgeCode.replaceAll(' ', '');
      if (noSpacesCode != catridgeCode) {
        final noSpacesResponse = await _tryCatridgeFormat(
          branchCode, 
          noSpacesCode, 
          requestHeaders,
          requiredStandValue: requiredStandValue,
          requiredType: requiredType,
          existingCatridges: existingCatridges,
        );
        
        if (noSpacesResponse.success) {
          return noSpacesResponse;
        }
      }
      
      // If no spaces fails, try with "ATM " prefix if not already present
      if (!catridgeCode.toUpperCase().startsWith('ATM ')) {
        final withAtmResponse = await _tryCatridgeFormat(
          branchCode, 
          'ATM ${catridgeCode.trim()}', 
          requestHeaders,
          requiredStandValue: requiredStandValue,
          requiredType: requiredType,
          existingCatridges: existingCatridges,
        );
        
        if (withAtmResponse.success) {
          return withAtmResponse;
        }
      }
      
      // If all formats fail, return the original error
      return ApiResponse(
        success: false,
        message: 'Catridge tidak ditemukan. Periksa kembali nomor catridge.',
        status: 'error',
      );
    } catch (e) {
      debugPrint('Catridge details API error: $e');
      return ApiResponse(
        success: false,
        message: 'Error validating catridge: ${e.toString()}',
        status: 'error'
      );
    }
  }
  
  // Helper method to try different catridge formats
  Future<ApiResponse> _tryCatridgeFormat(
    String branchCode, 
    String catridgeCode, 
    Map<String, String> headers, {
    int? requiredStandValue,
    String? requiredType,
    List<String>? existingCatridges,
  }) async {
    try {
      final encodedCatridgeCode = Uri.encodeComponent(catridgeCode);
      
      // Build URL with optional parameters
      String url = '$_currentBaseUrl/CRF/catridge/list?branchCode=$branchCode&catridgeCode=$encodedCatridgeCode';
      
      // Add optional parameters if provided
      if (requiredStandValue != null) {
        url += '&requiredStandValue=$requiredStandValue';
      }
      
      if (requiredType != null) {
        url += '&requiredType=$requiredType';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final apiResponse = ApiResponse.fromJson(jsonData);
        
        // Filter out catridges that are already in use if needed
        if (existingCatridges != null && existingCatridges.isNotEmpty && apiResponse.success && apiResponse.data != null) {
          final dataList = apiResponse.data as List<dynamic>;
          final filteredData = dataList.where((item) {
            final code = item['Code'] ?? item['code'] ?? '';
            return !existingCatridges.contains(code);
          }).toList();
          
          // Update the response with filtered data
          if (filteredData.isEmpty && dataList.isNotEmpty) {
            return ApiResponse(
              success: false,
              message: 'Catridge sudah digunakan dalam trip ini.',
              status: 'error'
            );
          }
          
          // Create a new response with filtered data
          final Map<String, dynamic> filteredResponse = {
            'success': apiResponse.success,
            'message': apiResponse.message,
            'data': filteredData,
          };
          
          return ApiResponse.fromJson(filteredResponse);
        }
        
        return apiResponse;
      } else {
        return ApiResponse(
          success: false,
          message: 'Server error (${response.statusCode})',
          status: 'error'
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error: ${e.toString()}',
        status: 'error'
      );
    }
  }

  // Validate Seal Code
  Future<ApiResponse> validateSeal(String sealCode) async {
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
          return ApiResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing seal validation JSON: $e');
          return ApiResponse(
            success: false,
            message: 'Invalid data format from server',
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
      debugPrint('Seal validation API error: $e');
      
      String errorMessage = 'Network error: ${e.toString()}';
      if (e is TimeoutException) {
        errorMessage = 'Connection timeout: Please check your internet connection';
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
        status: 'error'
      );
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

  // Approve prepare data using QR code (for TL approval via QR scanning)
  Future<ApiResponse> approvePrepareWithQR(String idTool, String tlNik) async {
    try {
      final requestHeaders = await headers;
      
      final requestBody = {
        "idTool": idTool,
        "tlNik": tlNik,
      };
      
      print('Approve Prepare with QR request: ${json.encode(requestBody)}');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/approve-prepare-qr'),
          headers: requestHeaders,
          body: json.encode(requestBody),
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('Approve Prepare with QR response: ${response.body}');
          return ApiResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing Approve Prepare with QR JSON: $e');
          return ApiResponse(
            success: false,
            message: 'Invalid data format from server',
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
      debugPrint('Approve Prepare with QR API error: $e');
      
      String errorMessage = 'Network error: ${e.toString()}';
      if (e is TimeoutException) {
        errorMessage = 'Connection timeout: Please check your internet connection';
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
        status: 'error'
      );
    }
  }

  // Get Return Header and Catridge data by ID
  Future<ReturnHeaderResponse> getReturnHeaderAndCatridge(String idTool, {String branchCode = "0"}) async {
    try {
      final requestHeaders = await headers;
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.get(
          Uri.parse('$baseUrl/CRF/return/header-and-catridge/$idTool?branchCode=$branchCode'),
          headers: requestHeaders,
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('Return header response: ${response.body}');
          
          // Handle business validation errors that come with 200 status
          if (jsonData['success'] == false) {
            return ReturnHeaderResponse(
              success: false,
              message: jsonData['message'] ?? 'Terjadi kesalahan',
              header: null,
              data: [],
            );
          }
          
          return ReturnHeaderResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing return header JSON: $e');
          return ReturnHeaderResponse(
            success: false,
            message: 'Format data tidak valid: ${e.toString()}',
            header: null,
            data: [],
          );
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        return ReturnHeaderResponse(
          success: false,
          message: 'Sesi telah berakhir. Silakan login kembali.',
          header: null,
          data: [],
        );
      } else {
        String errorMessage = 'Terjadi kesalahan server';
        try {
          final errorJson = json.decode(response.body);
          errorMessage = errorJson['message'] ?? errorMessage;
        } catch (_) {}
        
        return ReturnHeaderResponse(
          success: false,
          message: '$errorMessage (${response.statusCode})',
          header: null,
          data: [],
        );
      }
    } catch (e) {
      debugPrint('Return header API error: $e');
      String errorMessage = 'Terjadi kesalahan jaringan';
      
      if (e.toString().contains('serah terima pulang')) {
        errorMessage = 'Trip ini belum melakukan serah terima pulang. Silakan selesaikan proses serah terima di menu CPC terlebih dahulu.';
      } else if (e is TimeoutException) {
        errorMessage = 'Koneksi timeout. Silakan periksa koneksi internet Anda.';
      }
      
      return ReturnHeaderResponse(
        success: false,
        message: errorMessage,
        header: null,
        data: [],
      );
    }
  }
  
  // Update Planning RTN for TL approval
  Future<ApiResponse> updatePlanningRTN(Map<String, dynamic> parameters) async {
    try {
      final requestHeaders = await headers;
      
      // Format date parameters properly
      if (parameters.containsKey('DateStartReturn') && parameters['DateStartReturn'] is String) {
        // Make sure it's in a format the API can understand
        final dateStr = parameters['DateStartReturn'];
        try {
          final date = DateTime.parse(dateStr);
          parameters['DateStartReturn'] = date.toIso8601String();
        } catch (e) {
          // Keep original if parsing fails
        }
      }
      
      // Ensure idTool is numeric
      if (parameters.containsKey('idTool')) {
        try {
          final idTool = int.tryParse(parameters['idTool'].toString());
          if (idTool != null) {
            parameters['idTool'] = idTool;
          }
        } catch (e) {
          // Keep as is if parsing fails
        }
      }
      
      print('Update Planning RTN request: ${json.encode(parameters)}');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/rtn/planning/update'),
          headers: requestHeaders,
          body: json.encode(parameters),
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('Update Planning RTN response: ${response.body}');
          return ApiResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing update planning RTN JSON: $e');
          return ApiResponse(
            success: false,
            message: 'Invalid update planning RTN data format from server',
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
        String errorMessage = 'Server error (${response.statusCode})';
        try {
          final errorJson = json.decode(response.body);
          errorMessage = errorJson['message'] ?? errorMessage;
        } catch (_) {}
        
        return ApiResponse(
          success: false,
          message: errorMessage,
          status: 'error'
        );
      }
    } catch (e) {
      debugPrint('Update Planning RTN API error: $e');
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        status: 'error'
      );
    }
  }

  // Validate Return Catridge using RTN_SP_ReturnCatridge
  Future<ReturnCatridgeValidationResponse> validateReturnCatridge({
    required String idTool,
    String branchCode = "0",
  }) async {
    try {
      final requestHeaders = await headers;
      
      // Build query parameters
      final queryParams = <String, String>{
        'idTool': idTool,
        'branchCode': branchCode,
      };
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.get(
          Uri.parse('$baseUrl/CRF/rtn/return/catridge').replace(queryParameters: queryParams),
          headers: requestHeaders,
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return ReturnCatridgeValidationResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing Return Catridge validation JSON: $e');
          return ReturnCatridgeValidationResponse(
            success: false,
            message: 'Invalid data format from server',
            data: null,
          );
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        return ReturnCatridgeValidationResponse(
          success: false,
          message: 'Session expired: Please login again',
          data: null,
        );
      } else {
        return ReturnCatridgeValidationResponse(
          success: false,
          message: 'Server error (${response.statusCode}): ${response.body}',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Return Catridge validation API error: $e');
      
      String errorMessage = 'Network error: ${e.toString()}';
      if (e is TimeoutException) {
        errorMessage = 'Connection timeout: Please check your internet connection';
      }
      
      return ReturnCatridgeValidationResponse(
        success: false,
        message: errorMessage,
        data: null,
      );
    }
  }
  
  // Get Catridge Replenish data using RTN_SP_CatridgeReplenish
  Future<CatridgeReplenishResponse> getCatridgeReplenish(String catridge) async {
    try {
      final requestHeaders = await headers;
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.get(
          Uri.parse('$baseUrl/CRF/rtn/catridge/replenish/$catridge'),
          headers: requestHeaders,
        ),
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return CatridgeReplenishResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing Catridge Replenish JSON: $e');
          return CatridgeReplenishResponse(
            success: false,
            message: 'Invalid data format from server',
            data: [],
          );
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        return CatridgeReplenishResponse(
          success: false,
          message: 'Session expired: Please login again',
          data: [],
        );
      } else {
        return CatridgeReplenishResponse(
          success: false,
          message: 'Server error (${response.statusCode}): ${response.body}',
          data: [],
        );
      }
    } catch (e) {
      debugPrint('Catridge Replenish API error: $e');
      
      String errorMessage = 'Network error: ${e.toString()}';
      if (e is TimeoutException) {
        errorMessage = 'Connection timeout: Please check your internet connection';
      }
      
      return CatridgeReplenishResponse(
        success: false,
        message: errorMessage,
        data: [],
      );
    }
  }
  
  // Validate and Get Replenish in one call
  Future<ValidateAndGetReplenishResponse> validateAndGetReplenish({
    required String idTool,
    String catridgeCode = "",
    String branchCode = "0",
  }) async {
    try {
      // Ensure branchCode is numeric
      String numericBranchCode = branchCode;
      if (branchCode.isEmpty || !RegExp(r'^\d+$').hasMatch(branchCode)) {
        numericBranchCode = '1'; // Default to '1' if not numeric
        print('validateAndGetReplenish: Branch code is not numeric: "$branchCode", using default: $numericBranchCode');
      } else {
        print('validateAndGetReplenish: Using numeric branch code: $numericBranchCode');
      }
      
      final requestHeaders = await headers;
      
      // Build query parameters with proper URI encoding
      final uri = Uri.parse('$_currentBaseUrl/CRF/rtn/validate-and-get-replenish');
      
      // Prepare query parameters
      final queryParams = <String, String>{
        'idtool': idTool,
        'branchCode': numericBranchCode,
      };
      
      if (catridgeCode.isNotEmpty) {
        queryParams['catridgeCode'] = catridgeCode;
      }
      
      // Log request for debugging
      debugPrint('validateAndGetReplenish: $queryParams');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) {
          final baseUri = Uri.parse('$baseUrl/CRF/rtn/validate-and-get-replenish')
              .replace(queryParameters: queryParams);
          return http.get(baseUri, headers: requestHeaders);
        },
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return ValidateAndGetReplenishResponse.fromJson(jsonData);
        } catch (e) {
          debugPrint('Error parsing ValidateAndGetReplenish JSON: $e');
          return ValidateAndGetReplenishResponse(
            success: false,
            message: 'Invalid data format from server',
            data: null,
          );
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        return ValidateAndGetReplenishResponse(
          success: false,
          message: 'Session expired: Please login again',
          data: null,
        );
      } else {
        return ValidateAndGetReplenishResponse(
          success: false,
          message: 'Server error (${response.statusCode}): ${response.body}',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('ValidateAndGetReplenish API error: $e');
      
      String errorMessage = 'Network error: ${e.toString()}';
      if (e is TimeoutException) {
        errorMessage = 'Connection timeout: Please check your internet connection';
      }
      
      return ValidateAndGetReplenishResponse(
        success: false,
        message: errorMessage,
        data: null,
      );
    }
  }

  // Validate and get replenish data in one call
  Future<Map<String, dynamic>> validateAndGetReplenishRaw(String idTool, String branchCode, {String? catridgeCode}) async {
    try {
      // Ensure branchCode is numeric
      String numericBranchCode = branchCode;
      if (branchCode.isEmpty || !RegExp(r'^\d+$').hasMatch(branchCode)) {
        numericBranchCode = '1'; // Default to '1' if not numeric
        print('WARNING: Branch code is not numeric: "$branchCode", using default: $numericBranchCode');
      } else {
        print('Using numeric branch code: $numericBranchCode');
      }
      
      // Check authentication status first
      await checkAndRefreshAuth();
      
      // APPROACH 1: Direct HTTP request without auth headers
      final directUri = Uri.parse('http://10.10.0.223/LocalCRF/api/CRF/rtn/validate-and-get-replenish')
          .replace(queryParameters: {
            'idtool': idTool,
            'branchCode': numericBranchCode,
            if (catridgeCode != null && catridgeCode.trim().isNotEmpty) 'catridgeCode': catridgeCode,
          });
      
      debugPrint('APPROACH 1 - DIRECT TEST URL: ${directUri.toString()}');
      
      try {
        // First try direct request without auth
        final directResponse = await http.get(directUri).timeout(const Duration(seconds: 10));
        debugPrint('Direct response status: ${directResponse.statusCode}');
        
        if (directResponse.statusCode == 200) {
          // If direct request works, use that response
          debugPrint('Direct request successful, using response');
          final jsonData = json.decode(directResponse.body);
          return jsonData;
        } else {
          debugPrint('Direct request failed with status ${directResponse.statusCode}');
        }
      } catch (directError) {
        debugPrint('Direct request error: $directError');
      }
      
      // APPROACH 2: Try with Dio
      debugPrint('APPROACH 2 - Trying with Dio...');
      final dioResult = await tryWithDio(idTool, numericBranchCode, catridgeCode: catridgeCode);
      if (dioResult['success'] == true) {
        debugPrint('Dio request successful');
        return dioResult;
      }
      debugPrint('Dio request failed');
      
      // APPROACH 3: Try with path parameters
      debugPrint('APPROACH 3 - Trying with path parameters...');
      final pathResult = await tryWithPathParams(idTool, numericBranchCode, catridgeCode: catridgeCode);
      if (pathResult['success'] == true) {
        debugPrint('Path parameters request successful');
        return pathResult;
      }
      debugPrint('Path parameters request failed');
      
      // APPROACH 4: Try with POST instead of GET
      debugPrint('APPROACH 4 - Trying with POST...');
      final postResult = await tryWithPost(idTool, numericBranchCode, catridgeCode: catridgeCode);
      if (postResult['success'] == true) {
        debugPrint('POST request successful');
        return postResult;
      }
      debugPrint('POST request failed');
      
      // APPROACH 5: Original implementation with auth
      debugPrint('APPROACH 5 - Trying original implementation with auth...');
      final requestHeaders = await headers;
      
      // Use Uri class properly for query parameters instead of manual URL construction
      final uri = Uri.parse('$_currentBaseUrl/CRF/rtn/validate-and-get-replenish');
      
      // Construct the query parameters with proper encoding
      final queryParams = {
        'idtool': idTool,
        'branchCode': numericBranchCode,
      };
      
      // Add catridgeCode parameter only if it's not null and not empty
      if (catridgeCode != null && catridgeCode.trim().isNotEmpty) {
        queryParams['catridgeCode'] = catridgeCode;
        debugPrint('Including catridgeCode in request: $catridgeCode');
      } else {
        debugPrint('catridgeCode is empty or null, excluding from request');
      }
      
      // Log the request details for debugging
      debugPrint('Request: GET ${uri.path}');
      debugPrint('Parameters: $queryParams');
      debugPrint('Headers: ${requestHeaders.toString()}');
      
      // Create URI with query parameters
      final requestUri = uri.replace(queryParameters: queryParams);
      debugPrint('Full URL: ${requestUri.toString()}');
      
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) {
          // Create a new URI with the current baseUrl
          final baseUri = Uri.parse('$baseUrl/CRF/rtn/validate-and-get-replenish')
              .replace(queryParameters: queryParams);
          return http.get(baseUri, headers: requestHeaders);
        },
      );
      
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response body preview: ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}');
      
      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          return jsonData;
        } catch (e) {
          debugPrint('Error parsing ValidateAndGetReplenish JSON: $e');
          return {
            'success': false,
            'message': 'Gagal memproses data dari server: ${e.toString()}'
          };
        }
      } else if (response.statusCode == 401) {
        await _authService.logout();
        return {
          'success': false,
          'message': 'Sesi anda telah berakhir, silakan login kembali'
        };
      } else if (response.statusCode == 404) {
        // More detailed 404 error with parameters and complete URL
        final String fullUrl = '$_currentBaseUrl/CRF/rtn/validate-and-get-replenish?idtool=$idTool&branchCode=$numericBranchCode${catridgeCode != null && catridgeCode.isNotEmpty ? '&catridgeCode=$catridgeCode' : ''}';
        return {
          'success': false,
          'message': 'Endpoint API tidak ditemukan (404). Mohon periksa konfigurasi server.\n\n' +
                    'Detail: GET /CRF/rtn/validate-and-get-replenish\n' +
                    'Parameter: idtool=$idTool, branchCode=$numericBranchCode${catridgeCode != null && catridgeCode.isNotEmpty ? ', catridgeCode=$catridgeCode' : ''}\n\n' +
                    'URL Lengkap: $fullUrl\n\n' +
                    'Coba akses URL ini di browser untuk memverifikasi: http://10.10.0.223/LocalCRF/api/CRF/rtn/validate-and-get-replenish?idtool=$idTool&branchCode=$numericBranchCode'
        };
      } else {
        // Better error message with response details
        String errorDetail = '';
        try {
          // Try to extract any error information from the response body
          final errorJson = json.decode(response.body);
          if (errorJson.containsKey('message')) {
            errorDetail = errorJson['message'];
          } else if (errorJson.containsKey('error')) {
            errorDetail = errorJson['error'];
          }
        } catch (e) {
          // If not valid JSON, use raw response
          errorDetail = response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body;
        }
        
        return {
          'success': false,
          'message': 'Kesalahan server (${response.statusCode})\n\nDetail: $errorDetail\n\nParameter: idtool=$idTool, branchCode=$numericBranchCode${catridgeCode != null && catridgeCode.isNotEmpty ? ', catridgeCode=$catridgeCode' : ''}'
        };
      }
    } catch (e) {
      debugPrint('ValidateAndGetReplenish API error: $e');
      
      String errorMessage = 'Kesalahan jaringan: ${e.toString()}';
      if (e is TimeoutException) {
        errorMessage = 'Koneksi timeout: Mohon periksa koneksi internet anda';
      }
      
      // Include request parameters in error message
      errorMessage += '\n\nParameter yang digunakan:\nidTool: $idTool\nbranchCode: $branchCode';
      if (catridgeCode != null && catridgeCode.isNotEmpty) {
        errorMessage += '\ncatridgeCode: $catridgeCode';
      }
      
      return {
        'success': false,
        'message': errorMessage
      };
    }
  }

  // Try API call using Dio instead of http
  Future<Map<String, dynamic>> tryWithDio(String idTool, String branchCode, {String? catridgeCode}) async {
    try {
      // Ensure branchCode is numeric
      String numericBranchCode = branchCode;
      if (branchCode.isEmpty || !RegExp(r'^\d+$').hasMatch(branchCode)) {
        numericBranchCode = '1'; // Default to '1' if not numeric
        print('Dio: Branch code is not numeric: "$branchCode", using default: $numericBranchCode');
      }
      
      final dio = Dio();
      
      // Set timeout
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);
      
      // Get auth token
      final token = await _authService.getToken();
      
      // Set headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Add auth token if available
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      // Prepare query parameters
      final queryParams = {
        'idtool': idTool,
        'branchCode': numericBranchCode,
      };
      
      if (catridgeCode != null && catridgeCode.trim().isNotEmpty) {
        queryParams['catridgeCode'] = catridgeCode;
      }
      
      // Log request details
      debugPrint('Dio request to: $_currentBaseUrl/CRF/rtn/validate-and-get-replenish');
      debugPrint('Dio params: $queryParams');
      
      // Make request
      final response = await dio.get(
        '$_currentBaseUrl/CRF/rtn/validate-and-get-replenish',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      
      // Log response
      debugPrint('Dio response status: ${response.statusCode}');
      
      // Parse response
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Dio error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Try API call with parameters in URL path
  Future<Map<String, dynamic>> tryWithPathParams(String idTool, String branchCode, {String? catridgeCode}) async {
    try {
      // Ensure branchCode is numeric
      String numericBranchCode = branchCode;
      if (branchCode.isEmpty || !RegExp(r'^\d+$').hasMatch(branchCode)) {
        numericBranchCode = '1'; // Default to '1' if not numeric
        print('PathParams: Branch code is not numeric: "$branchCode", using default: $numericBranchCode');
      }
      
      // Build URL with parameters in path
      String url = 'http://10.10.0.223/LocalCRF/api/CRF/rtn/validate-and-get-replenish/$idTool/$numericBranchCode';
      if (catridgeCode != null && catridgeCode.trim().isNotEmpty) {
        url += '/$catridgeCode';
      }
      
      debugPrint('Trying with path parameters: $url');
      
      // Make request
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      // Log response
      debugPrint('Path params response status: ${response.statusCode}');
      
      // Parse response
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Path params error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Try API call with POST instead of GET
  Future<Map<String, dynamic>> tryWithPost(String idTool, String branchCode, {String? catridgeCode}) async {
    try {
      // Ensure branchCode is numeric
      String numericBranchCode = branchCode;
      if (branchCode.isEmpty || !RegExp(r'^\d+$').hasMatch(branchCode)) {
        numericBranchCode = '1'; // Default to '1' if not numeric
        print('POST: Branch code is not numeric: "$branchCode", using default: $numericBranchCode');
      }
      
      // Get auth token
      final token = await _authService.getToken();
      
      // Set headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Add auth token if available
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      // Prepare request body
      final body = {
        'idtool': idTool,
        'branchCode': numericBranchCode,
      };
      
      if (catridgeCode != null && catridgeCode.trim().isNotEmpty) {
        body['catridgeCode'] = catridgeCode;
      }
      
      // Log request details
      debugPrint('POST request to: $_currentBaseUrl/CRF/rtn/validate-and-get-replenish');
      debugPrint('POST body: $body');
      
      // Make request
      final response = await http.post(
        Uri.parse('$_currentBaseUrl/CRF/rtn/validate-and-get-replenish'),
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));
      
      // Log response
      debugPrint('POST response status: ${response.statusCode}');
      
      // Parse response
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        return {
          'success': false,
          'message': 'Server error (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('POST error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Check authentication status and refresh token if needed
  Future<bool> checkAndRefreshAuth() async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('No authentication token found');
        return false;
      }
      
      // Check if token is expired by trying to decode it
      try {
        // Simple check - not full JWT validation
        final parts = token.split('.');
        if (parts.length != 3) {
          debugPrint('Invalid token format');
          return false;
        }
        
        // Decode payload
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final Map<String, dynamic> data = json.decode(decoded);
        
        // Check exp claim
        if (data.containsKey('exp')) {
          final exp = data['exp'];
          final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          final now = DateTime.now();
          
          if (expDate.isBefore(now)) {
            debugPrint('Token expired, attempting refresh');
            // Try to refresh token
            final refreshResult = await _refreshToken();
            return refreshResult;
          }
        }
        
        debugPrint('Token appears valid');
        return true;
      } catch (e) {
        debugPrint('Error checking token: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error in checkAndRefreshAuth: $e');
      return false;
    }
  }
  
  // Refresh authentication token
  Future<bool> _refreshToken() async {
    try {
      final requestHeaders = await headers;
      final response = await _tryRequestWithFallback(
        requestFn: (baseUrl) => http.post(
          Uri.parse('$baseUrl/CRF/refresh-token'),
          headers: requestHeaders,
        ),
      );
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final newToken = jsonData['data']['token'];
          await _authService.saveToken(newToken);
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
} 
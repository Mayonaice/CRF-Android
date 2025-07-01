import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prepare_model.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://10.10.0.223/LocalCRF/api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Auth service
  final AuthService _authService = AuthService();

  // Get headers for API requests with authorization token
  Future<Map<String, String>> get headers async {
    final token = await _authService.getToken();
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Get ATM Prepare Replenish data by ID
  Future<PrepareReplenishResponse> getATMPrepareReplenish(int id) async {
    try {
      final requestHeaders = await headers;
      
      final response = await http.get(
        Uri.parse('$baseUrl/CRF/atm/prepare-replenish/$id'),
        headers: requestHeaders,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PrepareReplenishResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again to continue');
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
} 
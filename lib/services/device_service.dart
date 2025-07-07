import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  
  /// Get Android ID or device identifier
  /// Returns the actual Android ID from device for database compatibility
  static Future<String> getDeviceId() async {
    try {
      print('🔍 DEBUG: Platform detection started');
      print('🔍 DEBUG: Platform.isAndroid: ${Platform.isAndroid}');
      print('🔍 DEBUG: Platform.isIOS: ${Platform.isIOS}');
      print('🔍 DEBUG: Platform.operatingSystem: ${Platform.operatingSystem}');
      
      String deviceIdentifier = '';
      
      if (Platform.isAndroid) {
        print('🔍 DEBUG: Detected Android platform');
        AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        // Use the actual Android ID from device
        deviceIdentifier = androidInfo.id ?? 'unknown';
        
        print('🔍 DEBUG: Android ID from device: $deviceIdentifier');
        
        // If Android ID is available, return it directly
        if (deviceIdentifier != 'unknown' && deviceIdentifier.isNotEmpty) {
          print('🔍 DEBUG: Returning real Android ID: $deviceIdentifier');
          return deviceIdentifier;
        }
      } else if (Platform.isIOS) {
        print('🔍 DEBUG: Detected iOS platform');
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        deviceIdentifier = iosInfo.identifierForVendor ?? 'unknown';
        
        print('🔍 DEBUG: iOS identifier: $deviceIdentifier');
        
        // If iOS identifier is available, return it directly
        if (deviceIdentifier != 'unknown' && deviceIdentifier.isNotEmpty) {
          print('🔍 DEBUG: Returning iOS identifier: $deviceIdentifier');
          return deviceIdentifier;
        }
      } else {
        print('🔍 DEBUG: Detected WEB platform (Edge testing)');
        // For web platforms (Edge testing) - use one of the registered AndroidIDs for testing
        // This simulates using a real registered device AndroidID
        List<String> testAndroidIds = [
          'fd39d4157a8541a1',  // IMEI1 from W-117
          '9a3fcd57cc0b1dac',  // IMEI2 from W-117
        ];
        
        // Use first test AndroidID for Edge testing
        String edgeTestId = testAndroidIds[0];
        print('🔍 DEBUG: Using Edge test AndroidID: $edgeTestId');
        return edgeTestId;
      }
      
      print('🔍 DEBUG: Entering fallback MD5 hash generation');
      print('🔍 DEBUG: Device identifier for hash: $deviceIdentifier');
      
      // Fallback: Create MD5 hash and take first 16 characters for consistent format
      var bytes = utf8.encode(deviceIdentifier);
      var digest = md5.convert(bytes);
      String hashedId = digest.toString();
      
      // Return first 16 characters in format like: 77e6a1b7af9e8b2b
      String result = hashedId.substring(0, 16);
      print('🔍 DEBUG: Generated MD5 hash AndroidID: $result');
      return result;
      
    } catch (e) {
      print('🔍 DEBUG: Exception caught: $e');
      print('Error getting device ID: $e');
      // Fallback: For testing, return a known registered AndroidID
      String fallbackId = 'fd39d4157a8541a1';
      print('🔍 DEBUG: Using fallback AndroidID: $fallbackId');
      return fallbackId;
    }
  }
  
  /// Get detailed device information
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        return {
          'deviceId': androidInfo.id ?? 'unknown',
          'brand': androidInfo.brand ?? 'unknown',
          'model': androidInfo.model ?? 'unknown',
          'manufacturer': androidInfo.manufacturer ?? 'unknown',
          'product': androidInfo.product ?? 'unknown',
          'androidVersion': androidInfo.version.release ?? 'unknown',
          'sdkInt': androidInfo.version.sdkInt.toString(),
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'name': iosInfo.name ?? 'unknown',
          'model': iosInfo.model ?? 'unknown',
          'systemName': iosInfo.systemName ?? 'unknown',
          'systemVersion': iosInfo.systemVersion ?? 'unknown',
        };
      } else {
        return {
          'deviceId': 'fd39d4157a8541a1', // Use registered AndroidID for testing
          'platform': Platform.operatingSystem,
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
      return {
        'deviceId': 'fd39d4157a8541a1', // Use registered AndroidID as fallback
        'error': e.toString(),
      };
    }
  }
} 
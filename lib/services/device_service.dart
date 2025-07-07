import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:android_id/android_id.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static const AndroidId _androidIdPlugin = AndroidId();
  
  /// Get Android ID - uses native AndroidID from device
  /// Returns consistent AndroidID format for all platforms
  static Future<String> getDeviceId() async {
    try {
      print('🔍 Getting device AndroidID');
      
      if (Platform.isAndroid) {
        print('🔍 Android platform detected');
        
        // Get native Android ID using android_id package
        String? nativeAndroidId = await _androidIdPlugin.getId();
        print('🔍 Native Android ID: $nativeAndroidId');
        
        if (nativeAndroidId != null && nativeAndroidId.isNotEmpty && nativeAndroidId != 'unknown') {
          // Check if AndroidID is already in desired format (16 hex chars)
          if (nativeAndroidId.length == 16 && RegExp(r'^[a-f0-9]+$').hasMatch(nativeAndroidId)) {
            print('🔍 AndroidID already in perfect 16-hex format: $nativeAndroidId');
            return nativeAndroidId;
          } else {
            // Convert to 16-character hex format if needed
            var bytes = utf8.encode(nativeAndroidId);
            var digest = md5.convert(bytes);
            String hashedId = digest.toString().substring(0, 16);
            
            print('🔍 Original AndroidID: $nativeAndroidId');
            print('🔍 Converted to 16-hex: $hashedId');
            return hashedId;
          }
        } else {
          print('⚠️ Failed to get native AndroidID, using fallback');
          // Fallback: get device info and hash
          AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
          String deviceId = androidInfo.id ?? 'android_fallback';
          
          var bytes = utf8.encode(deviceId);
          var digest = md5.convert(bytes);
          String hashedId = digest.toString().substring(0, 16);
          
          print('🔍 Fallback AndroidID: $hashedId');
          return hashedId;
        }
        
      } else if (Platform.isIOS) {
        print('🔍 iOS platform detected');
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        
        // Use iOS identifier for consistency
        String iosId = iosInfo.identifierForVendor ?? 'ios_unknown';
        
        // Convert to 16-character hex format
        var bytes = utf8.encode(iosId);
        var digest = md5.convert(bytes);
        String hashedId = digest.toString().substring(0, 16);
        
        print('🔍 iOS AndroidID format: $hashedId');
        return hashedId;
        
      } else {
        print('🔍 Web/Edge platform detected');
        
        // For web testing, generate consistent ID
        String webId = 'web_edge_browser_testing';
        var bytes = utf8.encode(webId);
        var digest = md5.convert(bytes);
        String hashedId = digest.toString().substring(0, 16);
        
        print('🔍 Web AndroidID format: $hashedId');
        return hashedId;
      }
      
    } catch (e) {
      print('❌ Error getting device ID: $e');
      
      // Simple fallback
      var bytes = utf8.encode('fallback_device_id');
      var digest = md5.convert(bytes);
      String fallbackId = digest.toString().substring(0, 16);
      
      print('🔍 Fallback AndroidID: $fallbackId');
      return fallbackId;
    }
  }
  
  /// Get detailed device information
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      String generatedAndroidId = await getDeviceId();
      
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        String? nativeAndroidId = await _androidIdPlugin.getId();
        
        return {
          'deviceId': generatedAndroidId,
          'nativeAndroidId': nativeAndroidId ?? 'unknown',
          'originalId': androidInfo.id ?? 'unknown',
          'brand': androidInfo.brand ?? 'unknown',
          'model': androidInfo.model ?? 'unknown',
          'manufacturer': androidInfo.manufacturer ?? 'unknown',
          'androidVersion': androidInfo.version.release ?? 'unknown',
          'platform': 'Android',
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        return {
          'deviceId': generatedAndroidId,
          'originalId': iosInfo.identifierForVendor ?? 'unknown',
          'name': iosInfo.name ?? 'unknown',
          'model': iosInfo.model ?? 'unknown',
          'systemName': iosInfo.systemName ?? 'unknown',
          'systemVersion': iosInfo.systemVersion ?? 'unknown',
          'platform': 'iOS',
        };
      } else {
        return {
          'deviceId': generatedAndroidId,
          'platform': Platform.operatingSystem,
        };
      }
    } catch (e) {
      print('❌ Error getting device info: $e');
      return {
        'deviceId': 'error_fallback_id',
        'error': e.toString(),
        'platform': 'Unknown',
      };
    }
  }
} 
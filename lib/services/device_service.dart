import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:android_id/android_id.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static const AndroidId _androidIdPlugin = AndroidId();
  
  /// Get Android ID - Real device AndroidID for production
  /// Returns 16-character AndroidID for registration validation
  static Future<String> getDeviceId() async {
    try {
      print('🔍 Getting real device AndroidID for production');
      
      if (Platform.isAndroid) {
        print('🔍 Android platform detected');
        
        // Get native Android ID using android_id package
        String? nativeAndroidId = await _androidIdPlugin.getId();
        print('🔍 Native Android ID: $nativeAndroidId');
        
        if (nativeAndroidId != null && nativeAndroidId.isNotEmpty && nativeAndroidId != 'unknown') {
          // Use native AndroidID directly if it's already 16 chars
          if (nativeAndroidId.length == 16 && RegExp(r'^[a-f0-9]+$').hasMatch(nativeAndroidId)) {
            print('✅ AndroidID already in 16-hex format: $nativeAndroidId');
            return nativeAndroidId;
          } else {
            // Keep original AndroidID - don't hash it
            // Admin should register the exact AndroidID from device
            print('✅ Using original AndroidID: $nativeAndroidId');
            return nativeAndroidId;
          }
        } else {
          print('⚠️ Failed to get native AndroidID, using device info fallback');
          // Fallback: use device-specific info
          AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
          String deviceSerial = androidInfo.id ?? androidInfo.fingerprint ?? 'android_fallback';
          
          print('✅ Fallback AndroidID: $deviceSerial');
          return deviceSerial;
        }
        
      } else if (Platform.isIOS) {
        print('🔍 iOS platform detected');
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        
        // Use iOS identifier - keep original format
        String iosId = iosInfo.identifierForVendor ?? 'ios_unknown';
        
        print('✅ iOS AndroidID: $iosId');
        return iosId;
        
      } else {
        print('🔍 Web/Desktop platform detected');
        
        // For web/desktop, use a predictable but unique ID
        String webId = 'web_platform_id';
        
        print('✅ Web AndroidID: $webId');
        return webId;
      }
      
    } catch (e) {
      print('❌ Error getting device ID: $e');
      
      // Simple fallback - return error identifier
      String fallbackId = 'error_unknown_device';
      
      print('⚠️ Fallback AndroidID: $fallbackId');
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
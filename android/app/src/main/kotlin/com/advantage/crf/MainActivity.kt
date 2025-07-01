package com.advantage.crf

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Bundle
import android.util.Log
import androidx.multidex.MultiDex
import android.content.Context
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    private val TAG = "CRF_APP"
    private val CHANNEL = "com.advantage.crf/app_channel"
    
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        // Enable multidex support
        try {
            MultiDex.install(this)
        } catch (e: Exception) {
            Log.e(TAG, "Error installing multidex: ${e.message}")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        try {
            super.onCreate(savedInstanceState)
        } catch (e: Exception) {
            Log.e(TAG, "Error in onCreate: ${e.message}")
            e.printStackTrace()
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        try {
            super.configureFlutterEngine(flutterEngine)

            // Set up method channel for native communication
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "getNativeInfo" -> {
                        try {
                            val info = mapOf(
                                "androidVersion" to android.os.Build.VERSION.RELEASE,
                                "sdkVersion" to android.os.Build.VERSION.SDK_INT.toString(),
                                "model" to android.os.Build.MODEL,
                                "manufacturer" to android.os.Build.MANUFACTURER,
                                "device" to android.os.Build.DEVICE
                            )
                            result.success(info)
                        } catch (e: Exception) {
                            result.error("NATIVE_ERROR", "Failed to get device info", e.message)
                        }
                    }
                    "getAppVersion" -> {
                        try {
                            val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
                            result.success(packageInfo.versionName)
                        } catch (e: Exception) {
                            result.error("VERSION_ERROR", "Failed to get app version", e.message)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error configuring flutter engine: ${e.message}")
            e.printStackTrace()
        }
    }
    
    override fun onDestroy() {
        try {
            super.onDestroy()
        } catch (e: Exception) {
            Log.e(TAG, "Error in onDestroy: ${e.message}")
            e.printStackTrace()
        }
    }
} 
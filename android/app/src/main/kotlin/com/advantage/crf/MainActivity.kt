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
import android.view.WindowManager
import android.view.View
import android.os.Build

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
            
            // Enable fullscreen mode to hide notification bar
            enableFullscreen()
        } catch (e: Exception) {
            Log.e(TAG, "Error in onCreate: ${e.message}")
            e.printStackTrace()
        }
    }
    
    // Method to enable fullscreen and hide notification bar
    private fun enableFullscreen() {
        try {
            Log.d(TAG, "Enabling fullscreen mode")
            
            // Hide only the status bar (notification bar) but keep the content visible
            window.setFlags(
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
            )
            
            // For Android API 30+ (Android 11+), use a less aggressive approach
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.setDecorFitsSystemWindows(false)
                window.decorView.windowInsetsController?.let { controller ->
                    // Only hide status bars, keep navigation visible
                    controller.hide(android.view.WindowInsets.Type.statusBars())
                    // Allow user to show bars with a swipe
                    controller.systemBarsBehavior = android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                }
            } else {
                // For older Android versions - less aggressive approach
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR // Make status bar icons dark
                )
            }
            
            Log.d(TAG, "Fullscreen mode enabled")
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling fullscreen: ${e.message}")
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
                    "toggleFullscreen" -> {
                        try {
                            val enable = call.argument<Boolean>("enable") ?: true
                            if (enable) {
                                enableFullscreen()
                            } else {
                                // Code to exit fullscreen if needed
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                    window.setDecorFitsSystemWindows(true)
                                    window.decorView.windowInsetsController?.let { controller ->
                                        controller.show(android.view.WindowInsets.Type.statusBars())
                                    }
                                } else {
                                    @Suppress("DEPRECATION")
                                    window.clearFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)
                                    window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
                                }
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FULLSCREEN_ERROR", "Failed to toggle fullscreen", e.message)
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
    
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            // Re-enable fullscreen when window regains focus
            enableFullscreen()
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
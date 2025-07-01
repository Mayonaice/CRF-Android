package io.flutter.app;

import android.content.Context;
import android.util.Log;
import androidx.annotation.CallSuper;
import androidx.multidex.MultiDex;
import io.flutter.view.FlutterMain;

/**
 * Flutter Application that provides MultiDex support for API level < 21
 * 
 * This class is crucial for apps with large method counts
 */
public class FlutterMultiDexApplication extends FlutterApplication {
    private static final String TAG = "FlutterMultiDexApp";

    @Override
    @CallSuper
    protected void attachBaseContext(Context base) {
        try {
            Log.d(TAG, "Attaching base context with MultiDex support");
            super.attachBaseContext(base);
            MultiDex.install(this);
        } catch (Exception e) {
            Log.e(TAG, "Error in attachBaseContext: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Override
    @CallSuper
    public void onCreate() {
        try {
            Log.d(TAG, "Application onCreate");
            // Initialize Flutter before calling super.onCreate()
            FlutterMain.startInitialization(this);
            super.onCreate();
            FlutterMain.ensureInitializationComplete(this, null);
        } catch (Exception e) {
            Log.e(TAG, "Error in onCreate: " + e.getMessage());
            e.printStackTrace();
        }
    }
} 
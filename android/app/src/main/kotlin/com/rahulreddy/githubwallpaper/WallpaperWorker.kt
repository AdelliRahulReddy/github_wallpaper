package com.rahulreddy.githubwallpaper

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import android.util.Log

/**
 * WallpaperWorker - Background Worker for Wallpaper Updates
 * 
 * This worker is scheduled by WorkManager to run periodically (every 1-2 hours)
 * even when the app is fully closed, battery restricted, or after device reboot.
 * 
 * Play Store Compliance:
 * - Uses standard WorkManager API (no special permissions required)
 * - Respects Android's Doze mode and battery optimization
 * - Does not use foreground services
 * - Does not bypass system restrictions
 */
class WallpaperWorker(
    context: Context,
    params: WorkerParameters
) : Worker(context, params) {

    companion object {
        private const val TAG = "WallpaperWorker"
        private const val CHANNEL_NAME = "github_wallpaper/background"
        private const val METHOD_UPDATE = "updateWallpaper"
    }

    override fun doWork(): Result {
        Log.i(TAG, "WallpaperWorker started - Background update triggered")

        return try {
            // Create a Flutter engine for background execution
            val flutterEngine = FlutterEngine(applicationContext)
            
            // Initialize Dart isolate with the app's main entry point
            flutterEngine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )

            // Set up method channel to communicate with Dart
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL_NAME
            )

            // Create a synchronization object to wait for result
            var updateResult: Boolean? = null
            val lock = Object()

            // Call the Dart method to update wallpaper
            channel.invokeMethod(METHOD_UPDATE, null, object : MethodChannel.Result {
                override fun success(result: Any?) {
                    synchronized(lock) {
                        updateResult = result as? Boolean ?: false
                        lock.notify()
                    }
                    Log.i(TAG, "Wallpaper update succeeded: $result")
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    synchronized(lock) {
                        updateResult = false
                        lock.notify()
                    }
                    Log.e(TAG, "Wallpaper update failed: $errorCode - $errorMessage")
                }

                override fun notImplemented() {
                    synchronized(lock) {
                        updateResult = false
                        lock.notify()
                    }
                    Log.e(TAG, "Wallpaper update method not implemented")
                }
            })

            // Wait for the update to complete (max 5 minutes)
            synchronized(lock) {
                lock.wait(5 * 60 * 1000)
            }

            // Clean up Flutter engine
            flutterEngine.destroy()

            // Return result based on update success
            when (updateResult) {
                true -> {
                    Log.i(TAG, "WallpaperWorker completed successfully")
                    Result.success()
                }
                false -> {
                    Log.w(TAG, "WallpaperWorker failed, will retry")
                    Result.retry()
                }
                null -> {
                    Log.w(TAG, "WallpaperWorker timed out, will retry")
                    Result.retry()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "WallpaperWorker exception: ${e.message}", e)
            Result.retry()
        }
    }
}

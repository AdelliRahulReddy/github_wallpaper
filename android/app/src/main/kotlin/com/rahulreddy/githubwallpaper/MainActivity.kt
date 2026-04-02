package com.rahulreddy.githubwallpaper

import android.provider.Settings
import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.graphics.BitmapFactory
import android.graphics.Rect
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "github_wallpaper/wallpaper",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "getDesiredMinimumSize" -> {
          try {
            val wm = WallpaperManager.getInstance(this)
            result.success(
              hashMapOf(
                "width" to wm.desiredMinimumWidth,
                "height" to wm.desiredMinimumHeight,
              ),
            )
          } catch (e: Exception) {
            result.success(null)
          }
        }
        "setWallpaperFromPath" -> {
          val path = call.argument<String>("path")
          val targetStr = call.argument<String>("target") ?: "both"

          if (path.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "Path is missing", null)
            return@setMethodCallHandler
          }

          val file = File(path)
          if (!file.exists()) {
            result.error("FILE_NOT_FOUND", "Wallpaper file not found at $path", null)
            return@setMethodCallHandler
          }

          try {
            val wm = WallpaperManager.getInstance(this)
            if (!wm.isWallpaperSupported) {
              result.error("WALLPAPER_UNSUPPORTED", "Wallpaper changes are not supported on this device", null)
              return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && !wm.isSetWallpaperAllowed) {
              result.error("WALLPAPER_NOT_ALLOWED", "Wallpaper changes are blocked by device policy", null)
              return@setMethodCallHandler
            }

            val supportsLock = Build.VERSION.SDK_INT >= Build.VERSION_CODES.N
            val normalizedTarget = when {
              targetStr == "lock" && !supportsLock -> "home"
              targetStr == "both" && !supportsLock -> "home"
              else -> targetStr
            }
            val boundsOptions = BitmapFactory.Options().apply {
              inJustDecodeBounds = true
            }
            BitmapFactory.decodeFile(path, boundsOptions)
            val visibleCrop =
              if (boundsOptions.outWidth > 0 && boundsOptions.outHeight > 0) {
                Rect(0, 0, boundsOptions.outWidth, boundsOptions.outHeight)
              } else {
                null
              }

            if (visibleCrop != null) {
              try {
                wm.suggestDesiredDimensions(visibleCrop.width(), visibleCrop.height())
              } catch (_: Exception) {
              }
            }

            fun setStream(which: Int) {
              FileInputStream(file).use { stream ->
                wm.setStream(stream, visibleCrop, true, which)
              }
            }

            fun setBitmap(which: Int) {
              val bitmap = BitmapFactory.decodeFile(path)
                ?: throw Exception("Bitmap decoding failed for $path")
              try {
                wm.setBitmap(bitmap, visibleCrop, true, which)
              } finally {
                bitmap.recycle()
              }
            }

            fun applyTarget(which: Int, label: String) {
              try {
                setStream(which)
              } catch (streamError: Exception) {
                try {
                  setBitmap(which)
                } catch (bitmapError: Exception) {
                  throw Exception("$label wallpaper apply failed: ${bitmapError.message ?: streamError.message}")
                }
              }
            }

            val systemRequested = normalizedTarget == "home" || normalizedTarget == "both"
            val lockRequested = supportsLock &&
              (normalizedTarget == "lock" || normalizedTarget == "both")

            if (systemRequested) {
              applyTarget(WallpaperManager.FLAG_SYSTEM, "home")
            }

            if (lockRequested) {
              applyTarget(WallpaperManager.FLAG_LOCK, "lock")
            }

            if (!systemRequested && !lockRequested) {
              result.error("INVALID_TARGET", "Unsupported wallpaper target: $targetStr", null)
              return@setMethodCallHandler
            }

            result.success(true)
          } catch (e: Exception) {
            result.error("SET_WALLPAPER_FAILED", "${e.javaClass.simpleName}: ${e.message}", null)
          }
        }
        "openLiveWallpaperPicker" -> {
          try {
            val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER)
            intent.putExtra(
              WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
              ComponentName(this, GitWallLiveWallpaperService::class.java),
            )
            startActivity(intent)
            result.success(true)
          } catch (e: Exception) {
            result.error("LIVE_WALLPAPER_FAILED", "${e.javaClass.simpleName}: ${e.message}", null)
          }
        }
        else -> result.notImplemented()
      }
    }

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "github_wallpaper/system",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "openNotificationSettings" -> {
          try {
            val intent =
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                  putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                }
              } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                  data = android.net.Uri.parse("package:$packageName")
                }
              }
            startActivity(intent)
            result.success(true)
          } catch (e: Exception) {
            result.error("OPEN_NOTIFICATION_SETTINGS_FAILED", "${e.javaClass.simpleName}: ${e.message}", null)
          }
        }
        else -> result.notImplemented()
      }
    }
  }
}

package com.rahulreddy.githubwallpaper

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import android.graphics.BitmapFactory
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
            val flags = when (targetStr) {
              "home" -> WallpaperManager.FLAG_SYSTEM
              "lock" -> WallpaperManager.FLAG_LOCK
              else -> WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
            }

            try {
              // Try combined setting first (Efficient)
              FileInputStream(file).use { stream ->
                wm.setStream(stream, null, true, flags)
              }
            } catch (e1: Exception) {
              // ATTEMPT 2: Sequential Setting (Fixes issues on some Xiaomi/Samsung implementations)
              try {
                if (targetStr == "both" || targetStr == "home") {
                  FileInputStream(file).use { s -> wm.setStream(s, null, true, WallpaperManager.FLAG_SYSTEM) }
                }
                if (targetStr == "both" || targetStr == "lock") {
                  FileInputStream(file).use { s -> wm.setStream(s, null, true, WallpaperManager.FLAG_LOCK) }
                }
              } catch (e2: Exception) {
                // ATTEMPT 3: Bitmap Fallback (Universal / Native decoded)
                val bitmap = BitmapFactory.decodeFile(path)
                if (bitmap != null) {
                  try {
                    if (targetStr == "both" || targetStr == "home") {
                      wm.setBitmap(bitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                    }
                    if (targetStr == "both" || targetStr == "lock") {
                      wm.setBitmap(bitmap, null, true, WallpaperManager.FLAG_LOCK)
                    }
                  } finally {
                    bitmap.recycle()
                  }
                } else {
                  throw Exception("Bitmap decoding failed: ${e2.message}")
                }
              }
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
  }
}

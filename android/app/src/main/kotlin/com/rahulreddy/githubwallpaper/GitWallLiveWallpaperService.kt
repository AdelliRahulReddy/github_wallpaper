package com.rahulreddy.githubwallpaper

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Shader
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import kotlin.math.sin
import java.io.File

class GitWallLiveWallpaperService : WallpaperService() {
  override fun onCreateEngine(): Engine {
    return GitWallEngine()
  }

  inner class GitWallEngine : Engine() {
    private val handler = Handler(Looper.getMainLooper())
    private val frameDelayMs = 33L
    private var visible = false
    private var phase = 0.0
    private var lastPath: String? = null
    private var lastLoadAt = 0L
    private var bitmap: Bitmap? = null

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val overlayPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    private val drawRunnable = object : Runnable {
      override fun run() {
        drawFrame(surfaceHolder)
        if (visible) {
          handler.postDelayed(this, frameDelayMs)
        }
      }
    }

    override fun onVisibilityChanged(visible: Boolean) {
      this.visible = visible
      if (visible) {
        handler.post(drawRunnable)
      } else {
        handler.removeCallbacks(drawRunnable)
      }
    }

    override fun onSurfaceDestroyed(holder: SurfaceHolder) {
      super.onSurfaceDestroyed(holder)
      visible = false
      handler.removeCallbacks(drawRunnable)
      bitmap?.recycle()
      bitmap = null
    }

    private fun readLatestWallpaperPath(context: Context): String? {
      return try {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.getString("flutter.wp_path", null)
      } catch (_: Exception) {
        null
      }
    }

    private fun maybeReloadBitmap() {
      val now = System.currentTimeMillis()
      if (now - lastLoadAt < 2500L) return
      lastLoadAt = now
      val path = readLatestWallpaperPath(this@GitWallLiveWallpaperService) ?: return
      if (path == lastPath && bitmap != null) return
      val f = File(path)
      if (!f.exists()) return
      val next = BitmapFactory.decodeFile(path) ?: return
      bitmap?.recycle()
      bitmap = next
      lastPath = path
    }

    private fun drawFrame(holder: SurfaceHolder) {
      maybeReloadBitmap()
      val b = bitmap
      var canvas: Canvas? = null
      try {
        canvas = holder.lockCanvas()
        if (canvas == null) return
        val w = canvas.width
        val h = canvas.height
        canvas.drawColor(0xFF0D1117.toInt())

        if (b != null) {
          val src = Rect(0, 0, b.width, b.height)
          val dst = Rect(0, 0, w, h)
          canvas.drawBitmap(b, src, dst, paint)
        }

        phase += 0.06
        val pulse = (0.10f + (0.08f * ((sin(phase) + 1.0) / 2.0))).toFloat()
        overlayPaint.shader = LinearGradient(
          0f, 0f, w.toFloat(), h.toFloat(),
          intArrayOf(
            0xFF39D353.toInt(),
            0xFF00B4D8.toInt(),
            0xFFFF79C6.toInt(),
          ),
          floatArrayOf(0f, 0.55f, 1f),
          Shader.TileMode.CLAMP
        )
        overlayPaint.alpha = (255f * pulse).toInt().coerceIn(0, 255)
        canvas.drawRect(0f, 0f, w.toFloat(), h.toFloat(), overlayPaint)
      } catch (_: Exception) {
      } finally {
        if (canvas != null) {
          try {
            holder.unlockCanvasAndPost(canvas)
          } catch (_: Exception) {
          }
        }
      }
    }
  }
}


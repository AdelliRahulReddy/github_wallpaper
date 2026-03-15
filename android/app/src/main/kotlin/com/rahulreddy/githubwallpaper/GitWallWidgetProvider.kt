package com.rahulreddy.githubwallpaper

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class GitWallWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: android.content.SharedPreferences,
  ) {
    val username = widgetData.getString("gitwall_username", "GitWall") ?: "GitWall"
    val streak = widgetData.getInt("gitwall_current_streak", 0)
    val today = widgetData.getInt("gitwall_today_commits", 0)

    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.gitwall_widget)
      views.setTextViewText(R.id.gitwall_widget_username, username)
      views.setTextViewText(R.id.gitwall_widget_streak_value, "${streak}d")
      views.setTextViewText(R.id.gitwall_widget_today_value, "$today")
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}


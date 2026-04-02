package com.rahulreddy.githubwallpaper

import android.appwidget.AppWidgetManager
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
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
    val badge = widgetData.getString("gitwall_widget_badge", "SYNC") ?: "SYNC"
    val status =
      widgetData.getString(
        "gitwall_widget_status",
        "Connect GitHub and sync once to turn the widget into a live contribution surface.",
      ) ?: "Connect GitHub and sync once to turn the widget into a live contribution surface."
    val route =
      widgetData.getString(
        "gitwall_widget_route",
        "gitwall://widget/home?source=home_widget&state=connect",
      ) ?: "gitwall://widget/home?source=home_widget&state=connect"

    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.gitwall_widget)
      views.setTextViewText(R.id.gitwall_widget_username, username)
      views.setTextViewText(R.id.gitwall_widget_badge, badge)
      views.setTextViewText(R.id.gitwall_widget_streak_value, "${streak}d")
      views.setTextViewText(R.id.gitwall_widget_today_value, "$today")
      views.setTextViewText(R.id.gitwall_widget_status, status)
      val pendingIntent =
        HomeWidgetLaunchIntent.getActivity(
          context,
          MainActivity::class.java,
          Uri.parse(route),
        )
      views.setOnClickPendingIntent(R.id.gitwall_widget_root, pendingIntent)
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}


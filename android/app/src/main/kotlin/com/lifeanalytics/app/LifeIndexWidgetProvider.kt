package com.lifeanalytics.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class LifeIndexWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_life_index).apply {
                val index = widgetData.getInt("life_index", -1)
                val sleep = widgetData.getString("sleep_hours", "—")
                val mood = widgetData.getString("mood", "—")
                val steps = widgetData.getString("steps", "—")

                if (index >= 0) {
                    setTextViewText(R.id.widget_index, index.toString())
                } else {
                    setTextViewText(R.id.widget_index, "—")
                }

                setTextViewText(R.id.widget_sleep, sleep ?: "—")
                setTextViewText(R.id.widget_mood, mood ?: "—")
                setTextViewText(R.id.widget_steps, steps ?: "—")

                val launchIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_index, launchIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}

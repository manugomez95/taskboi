package com.manugo.taskboi

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class TodayTasksWidget : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.today_tasks_widget)

            // Get task data from shared preferences
            val tasksJson = widgetData.getString("today_tasks", "[]") ?: "[]"
            val taskCount = widgetData.getInt("today_task_count", 0)
            val overdueCount = widgetData.getInt("overdue_count", 0)

            // Set header with task count
            val headerText = when {
                taskCount == 0 -> "Today"
                taskCount == 1 -> "Today · 1 task"
                else -> "Today · $taskCount tasks"
            }
            views.setTextViewText(R.id.widget_header, headerText)

            // Show overdue badge if needed
            if (overdueCount > 0) {
                views.setViewVisibility(R.id.overdue_badge, android.view.View.VISIBLE)
                views.setTextViewText(R.id.overdue_badge, "$overdueCount overdue")
            } else {
                views.setViewVisibility(R.id.overdue_badge, android.view.View.GONE)
            }

            // Setup ListView with tasks
            try {
                val tasks = JSONArray(tasksJson)

                if (tasks.length() > 0) {
                    // Show ListView, hide empty state
                    views.setViewVisibility(R.id.tasks_list, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.empty_state, android.view.View.GONE)

                    // Set up the RemoteViews adapter for the ListView
                    val serviceIntent = Intent(context, TaskWidgetService::class.java).apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
                        data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                    }
                    views.setRemoteAdapter(R.id.tasks_list, serviceIntent)

                    // Set up pending intent template for list item clicks
                    val clickIntent = Intent(context, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val clickPendingIntent = PendingIntent.getActivity(
                        context,
                        0,
                        clickIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                    )
                    views.setPendingIntentTemplate(R.id.tasks_list, clickPendingIntent)

                    // Set empty view for ListView
                    views.setEmptyView(R.id.tasks_list, R.id.empty_state)
                } else {
                    // Show empty state
                    views.setViewVisibility(R.id.tasks_list, android.view.View.GONE)
                    views.setViewVisibility(R.id.empty_state, android.view.View.VISIBLE)
                }

            } catch (e: Exception) {
                // Show error state
                views.setViewVisibility(R.id.tasks_list, android.view.View.GONE)
                views.setViewVisibility(R.id.empty_state, android.view.View.VISIBLE)
            }

            // Set click intent to open app
            val openAppUri = Uri.parse("taskboi://today")
            views.setOnClickPendingIntent(
                R.id.widget_header,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, openAppUri)
            )

            // Set add task button intent
            val addTaskUri = Uri.parse("taskboi://add")
            views.setOnClickPendingIntent(
                R.id.add_task_button,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, addTaskUri)
            )

            appWidgetManager.updateAppWidget(widgetId, views)

            // Notify the ListView to refresh its data
            appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.tasks_list)
        }
    }
}

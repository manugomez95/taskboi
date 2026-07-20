package com.manugo.taskboi

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class TaskWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TaskWidgetFactory(applicationContext)
    }
}

class TaskWidgetFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {

    private var tasks: List<TaskItem> = emptyList()

    data class TaskItem(
        val id: String,
        val title: String,
        val isCompleted: Boolean,
        val priority: Int
    )

    override fun onCreate() {
        loadTasks()
    }

    override fun onDataSetChanged() {
        loadTasks()
    }

    private fun loadTasks() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val tasksJson = widgetData.getString("today_tasks", "[]") ?: "[]"

        tasks = try {
            val jsonArray = JSONArray(tasksJson)
            (0 until jsonArray.length()).map { i ->
                val task = jsonArray.getJSONObject(i)
                TaskItem(
                    id = task.getString("id"),
                    title = task.getString("title"),
                    isCompleted = task.optBoolean("isCompleted", false),
                    priority = task.optInt("priority", 0)
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    override fun onDestroy() {
        tasks = emptyList()
    }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_task_item)

        if (position < tasks.size) {
            val task = tasks[position]

            views.setTextViewText(R.id.task_title, task.title)

            // Set checkbox appearance based on completion and priority
            val checkboxRes = if (task.isCompleted) {
                R.drawable.ic_checkbox_checked
            } else {
                when (task.priority) {
                    4 -> R.drawable.ic_checkbox_priority_1
                    3 -> R.drawable.ic_checkbox_priority_2
                    2 -> R.drawable.ic_checkbox_priority_3
                    else -> R.drawable.ic_checkbox_unchecked
                }
            }
            views.setImageViewResource(R.id.task_checkbox, checkboxRes)

            // Set fill-in intent for click handling
            val toggleIntent = Intent().apply {
                data = Uri.parse("taskboi://toggle/${task.id}")
            }
            views.setOnClickFillInIntent(R.id.task_checkbox, toggleIntent)

            val openIntent = Intent().apply {
                data = Uri.parse("taskboi://open/${task.id}")
            }
            views.setOnClickFillInIntent(R.id.task_title, openIntent)
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true
}

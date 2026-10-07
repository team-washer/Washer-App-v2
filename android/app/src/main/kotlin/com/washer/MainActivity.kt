package com.washer

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var notificationsChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()
        notificationsChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "washer/android-notifications",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "createNotificationChannel" -> {
                        createNotificationChannel()
                        result.success(null)
                    }
                    "showNotification" -> {
                        try {
                            result.success(showNotification(
                                call.argument<String>("messageId"),
                                call.argument<String>("title"),
                                call.argument<String>("body"),
                            ))
                        } catch (error: Exception) {
                            result.error("notification_display", "Unable to display notification", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        notificationsChannel?.setMethodCallHandler(null)
        notificationsChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(NotificationChannel(
                LAUNDRY_CHANNEL_ID,
                getString(R.string.laundry_notification_channel_name),
                NotificationManager.IMPORTANCE_HIGH,
            ))
        }
    }

    private fun showNotification(messageId: String?, title: String?, body: String?): Boolean {
        if (title.isNullOrBlank() && body.isNullOrBlank()) return false
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return false

        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && !manager.areNotificationsEnabled()) {
            return false
        }
        createNotificationChannel()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            manager.getNotificationChannel(LAUNDRY_CHANNEL_ID).importance == NotificationManager.IMPORTANCE_NONE
        ) return false

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, LAUNDRY_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setPriority(Notification.PRIORITY_HIGH)
                .setDefaults(Notification.DEFAULT_ALL)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .build()
        // The same FCM message replaces its existing notification rather than
        // adding another item. Messages without an ID remain independent.
        manager.notify(messageId ?: "foreground-${System.nanoTime()}", 0, notification)
        return true
    }

    companion object {
        private const val LAUNDRY_CHANNEL_ID = "laundry_completion"
    }
}

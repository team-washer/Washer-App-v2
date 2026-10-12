package com.washer

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()
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

    companion object {
        private const val LAUNDRY_CHANNEL_ID = "laundry_completion"
    }
}

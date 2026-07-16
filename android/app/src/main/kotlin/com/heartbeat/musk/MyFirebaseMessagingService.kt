package com.heartbeat.musk

import android.content.Intent
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        val data = remoteMessage.data
        if (data["action"] == "media_control") {
            val command = data["command"]
            if (command != null) {
                sendControlCommand(command)
            }
        }
    }

    private fun sendControlCommand(command: String) {
        val intent = Intent(this@MyFirebaseMessagingService, MediaNotificationListenerService::class.java).apply {
            action = MediaNotificationListenerService.ACTION_MEDIA_CONTROL
            putExtra(MediaNotificationListenerService.EXTRA_COMMAND, command)
        }
        try {
            startService(intent)
            Log.d("SoftSync", "Sent control command to service: $command")
        } catch (e: Exception) {
            Log.e("SoftSync", "Failed to start service for control command: ${e.message}")
            // Fallback to broadcast
            val broadcastIntent = Intent(MediaNotificationListenerService.ACTION_MEDIA_CONTROL).apply {
                putExtra(MediaNotificationListenerService.EXTRA_COMMAND, command)
                setPackage(packageName)
            }
            sendBroadcast(broadcastIntent)
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Token update is usually handled by Flutter side, 
        // but can be handled here if needed for native-only flow.
    }
}

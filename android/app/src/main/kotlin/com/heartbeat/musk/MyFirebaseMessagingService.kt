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
                sendControlBroadcast(command)
            }
        }
    }

    private fun sendControlBroadcast(command: String) {
        val intent = Intent(MediaNotificationListenerService.ACTION_MEDIA_CONTROL).apply {
            putExtra(MediaNotificationListenerService.EXTRA_COMMAND, command)
            setPackage(packageName)
        }
        sendBroadcast(intent)
        Log.d("SoftSync", "Sent control broadcast for command: $command")
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Token update is usually handled by Flutter side, 
        // but can be handled here if needed for native-only flow.
    }
}

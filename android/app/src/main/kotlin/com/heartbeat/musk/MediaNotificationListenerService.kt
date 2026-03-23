package com.heartbeat.musk

import android.content.ComponentName
import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.service.notification.NotificationListenerService
import android.util.Base64
import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.SetOptions
import java.io.ByteArrayOutputStream

class MediaNotificationListenerService : NotificationListenerService() {

    private lateinit var sessionManager: MediaSessionManager
    private var activeController: MediaController? = null

    override fun onCreate() {
        super.onCreate()
        sessionManager = getSystemService(MEDIA_SESSION_SERVICE) as MediaSessionManager
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        try {
            startListening()
        } catch (e: Exception) {
            Log.e("SoftSync", "Error starting listener: ${e.message}")
        }
    }

    private fun startListening() {
        val componentName = ComponentName(this, MediaNotificationListenerService::class.java)
        sessionManager.addOnActiveSessionsChangedListener({ controllers ->
            val controller = controllers?.firstOrNull {
                it.playbackState?.state == PlaybackState.STATE_PLAYING
            } ?: controllers?.firstOrNull()

            controller?.let { attachController(it) }
        }, componentName)

        val controllers = sessionManager.getActiveSessions(componentName)
        if (controllers.isNotEmpty()) {
            attachController(controllers[0])
        }
    }

    private fun attachController(controller: MediaController) {
        activeController?.unregisterCallback(mCallback)
        activeController = controller
        controller.registerCallback(mCallback)
        updateFirestore(controller)
    }

    private val mCallback = object : MediaController.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadata?) {
            activeController?.let { updateFirestore(it) }
        }

        override fun onPlaybackStateChanged(state: PlaybackState?) {
            activeController?.let { updateFirestore(it) }
        }
    }

    private fun updateFirestore(controller: MediaController) {
        val uid = FirebaseAuth.getInstance().currentUser?.uid ?: return
        val meta = controller.metadata
        val state = controller.playbackState

        if (meta == null || state == null || state.state == PlaybackState.STATE_STOPPED || state.state == PlaybackState.STATE_NONE) {
            clearFirestore(uid)
            return
        }

        val packageName = controller.packageName ?: ""

        val safeMeta = meta.toSafeMap()
        
        val title = safeMeta["title"] as? String ?: "Unknown"
        val artist = safeMeta["artist"] as? String ?: "Unknown"
        
        // Artwork extraction logic
        var albumArt = safeMeta["artwork"] as? String
        val duration = safeMeta["duration"]


        // If metadata doesn't have it, try extraction from the notification (crucial for YouTube)
        if (albumArt.isNullOrEmpty()) {
            val notificationBitmap = getArtworkFromNotification(packageName)
            if (notificationBitmap != null) {
                albumArt = bitmapToBase64(notificationBitmap)
            }
        }

        val isPlaying = state.state == PlaybackState.STATE_PLAYING

        val data = mutableMapOf(
            "title" to title,
            "artist" to artist,
            "albumArt" to albumArt,
            "duration" to duration,
            "isPlaying" to isPlaying,
            "isActive" to true,
            "packageName" to packageName,
            "playbackInfo" to controller.playbackInfo.toString(),
            "updatedAt" to FieldValue.serverTimestamp(),
            "source" to parseSource(packageName)
        )

        FirebaseFirestore.getInstance()
            .collection("nowplaying")
            .document(uid)
            .set(data, SetOptions.merge())
            .addOnFailureListener { e -> Log.e("SoftSync", "Firestore update failed: ${e.message}") }
    }

    private fun clearFirestore(uid: String) {
        val data = mapOf(
            "isActive" to false,
            "isPlaying" to false,
            "updatedAt" to FieldValue.serverTimestamp()
        )
        FirebaseFirestore.getInstance()
            .collection("nowplaying")
            .document(uid)
            .set(data, SetOptions.merge())
    }

    private fun getArtworkFromNotification(packageName: String): Bitmap? {
        return try {
            val notification = activeNotifications.firstOrNull { it.packageName == packageName }?.notification
                ?: return null
                
            val extras = notification.extras
            extras.getParcelable<Bitmap>(android.app.Notification.EXTRA_LARGE_ICON)
                ?: extras.getParcelable<Bitmap>(android.app.Notification.EXTRA_PICTURE)
                ?: extras.getParcelable<Bitmap>("android.picture")
        } catch (e: Exception) {
            null
        }
    }


}

fun parseSource(pkg: String): String {
    return when {
        pkg.contains("spotify") -> "Spotify"
        pkg.contains("youtube.music") -> "YouTube Music"
        pkg.contains("youtube") -> "YouTube"
        pkg.contains("apple") -> "Apple Music"
        else -> "Other"
    }
}
fun MediaMetadata.toSafeMap(): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    val description = this.description

    val title = description.title?.toString()
        ?: getString(MediaMetadata.METADATA_KEY_TITLE)
        ?: getString(MediaMetadata.METADATA_KEY_DISPLAY_TITLE)
    map["title"] = title

    val artist = description.subtitle?.toString()
        ?: getString(MediaMetadata.METADATA_KEY_ARTIST)
        ?: getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
        ?: getString(MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE)
        ?: getString(MediaMetadata.METADATA_KEY_AUTHOR)
    map["artist"] = artist

    map["album"] = getString(MediaMetadata.METADATA_KEY_ALBUM)
        ?: description.description?.toString()
        ?: getString(MediaMetadata.METADATA_KEY_DISPLAY_DESCRIPTION)

    // Artwork check in metadata
    val bitmap = description.iconBitmap
        ?: getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
        ?: getBitmap(MediaMetadata.METADATA_KEY_ART)
        ?: getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON)

    map["artwork"] = bitmapToBase64(bitmap)
        ?: description.iconUri?.toString()
        ?: getString(MediaMetadata.METADATA_KEY_ALBUM_ART_URI)
        ?: getString(MediaMetadata.METADATA_KEY_ART_URI)
        ?: getString(MediaMetadata.METADATA_KEY_DISPLAY_ICON_URI)

    map["duration"] = getLong(MediaMetadata.METADATA_KEY_DURATION)
    map["mediaId"] = description.mediaId ?: getString(MediaMetadata.METADATA_KEY_MEDIA_ID)

    return map
}

fun bitmapToBase64(bitmap: Bitmap?): String? {
    if (bitmap == null) return null
    return try {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 85, stream)
        val bytes = stream.toByteArray()
        Base64.encodeToString(bytes, Base64.NO_WRAP)
    } catch (e: Exception) {
        null
    }
}
fun isYouTube(packageName: String?): Boolean {
    return packageName == "com.google.android.youtube"
}
fun extractYoutubeThumbnail(meta: MediaMetadata): String? {
    val mediaId = meta.getString(MediaMetadata.METADATA_KEY_MEDIA_ID) ?: return null

    // if mediaId contains videoId
    return "https://img.youtube.com/vi/$mediaId/hqdefault.jpg"
}
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
        sessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
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

        // Handle case where music is stopped or null
        if (meta == null || state == null || state.state == PlaybackState.STATE_STOPPED || state.state == PlaybackState.STATE_NONE) {
            clearFirestore(uid)
            return
        }

        val title = meta.getString(MediaMetadata.METADATA_KEY_TITLE) ?: "Unknown"
        val artist = meta.getString(MediaMetadata.METADATA_KEY_ARTIST)
            ?: meta.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
            ?: "Unknown"

        val isPlaying = state.state == PlaybackState.STATE_PLAYING
        val packageName = controller.packageName ?: ""

        // Extract Album Art
        val bitmapArt = meta.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
            ?: meta.getBitmap(MediaMetadata.METADATA_KEY_ART)

        val albumArt = if (bitmapArt != null) bitmapToBase64(bitmapArt) else meta.getString(MediaMetadata.METADATA_KEY_ART_URI)

        val data = mapOf(
            "title" to title,
            "artist" to artist,
            "albumArt" to albumArt,
            "isPlaying" to isPlaying,
            "isActive" to true,
            "packageName" to packageName,
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

    private fun bitmapToBase64(bitmap: Bitmap): String {
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 70, stream)
        val bytes = stream.toByteArray()
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    private fun parseSource(pkg: String): String {
        return when {
            pkg.contains("spotify") -> "Spotify"
            pkg.contains("youtube.music") -> "YouTube Music"
            pkg.contains("youtube") -> "YouTube"
            pkg.contains("apple") -> "Apple Music"
            else -> "Other"
        }
    }
}

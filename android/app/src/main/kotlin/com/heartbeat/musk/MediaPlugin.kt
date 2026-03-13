package com.heartbeat.musk

import android.content.ComponentName
import android.content.Context
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.os.Build
import android.provider.Settings
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.graphics.Bitmap
import android.util.Base64
import java.io.ByteArrayOutputStream

class MediaPlugin : FlutterPlugin, EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var eventChannel: EventChannel
    private lateinit var methodChannel: MethodChannel

    private var eventSink: EventChannel.EventSink? = null
    private var sessionManager: MediaSessionManager? = null
    private var activeController: MediaController? = null

    companion object {
        const val EVENT_CHANNEL  = "com.nowplaying/media_events"
        const val METHOD_CHANNEL = "com.nowplaying/media"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasNotificationAccess" -> result.success(hasNotificationAccess())
                "openNotificationSettings" -> openNotificationSettings()
                else -> result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel.setStreamHandler(null)
        methodChannel.setMethodCallHandler(null)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        if (!hasNotificationAccess()) {
            events?.error("NO_PERMISSION", "Notification listener permission not granted", null)
            return
        }
        startMediaSessionListener()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        activeController?.unregisterCallback(mediaControllerCallback)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun startMediaSessionListener() {
        try {
            sessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
            val componentName = ComponentName(context, MediaNotificationListenerService::class.java)

            sessionManager?.addOnActiveSessionsChangedListener({ controllers ->

                val controller =
                    controllers?.firstOrNull {
                        it.playbackState?.state == PlaybackState.STATE_PLAYING
                    } ?: controllers?.firstOrNull()

                controller?.let { attachController(it) }

            }, componentName)

            // Immediately get current active session
            val controllers = sessionManager?.getActiveSessions(componentName)
            if (!controllers.isNullOrEmpty()) {
                attachController(controllers[0])
            }
        } catch (e: Exception) {
            eventSink?.error("SESSION_ERROR", e.message, null)
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun attachController(controller: MediaController) {
        activeController?.unregisterCallback(mediaControllerCallback)
        activeController = controller
        controller.registerCallback(mediaControllerCallback)

        // Emit current state immediately
        emitCurrentState(controller)
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun emitCurrentState(controller: MediaController) {
        val meta = controller.metadata
        val state = controller.playbackState

        if (meta != null && state != null) {
            emitMediaInfo(controller)
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private val mediaControllerCallback = object : MediaController.Callback() {
        override fun onMetadataChanged(metadata: android.media.MediaMetadata?) {
            activeController?.let { emitMediaInfo(it) }
        }

        override fun onPlaybackStateChanged(state: PlaybackState?) {
            val controller = activeController ?: return
            val playbackState = state?.state ?: return

            when (playbackState) {
                PlaybackState.STATE_STOPPED,
                PlaybackState.STATE_NONE -> {
                    eventSink?.success(null)
                }

                PlaybackState.STATE_PAUSED,
                PlaybackState.STATE_PLAYING,
                PlaybackState.STATE_BUFFERING -> {
                    emitMediaInfo(controller)
                }
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.LOLLIPOP)
    private fun emitMediaInfo(controller: MediaController) {
        val meta = controller.metadata ?: return

        val title = meta.getString(android.media.MediaMetadata.METADATA_KEY_TITLE) ?: return
        val artist = meta.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST)
            ?: meta.getString(android.media.MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
            ?: "Unknown"

        val packageName = controller.packageName ?: ""

        val state = controller.playbackState
        val isPlaying = state?.state == PlaybackState.STATE_PLAYING

        // --- Album art handling ---
        val bitmapArt =
            meta.getBitmap(android.media.MediaMetadata.METADATA_KEY_ALBUM_ART)
                ?: meta.getBitmap(android.media.MediaMetadata.METADATA_KEY_ART)

        val albumArt = bitmapToBase64(bitmapArt)
            ?: meta.getString(android.media.MediaMetadata.METADATA_KEY_ART_URI)

        val source = when {
            packageName.contains("spotify") -> "Spotify"
            packageName.contains("youtube.music") -> "YouTube Music"
            packageName.contains("youtube") -> "YouTube"
            packageName.contains("apple") -> "Apple Music"
            else -> "Other"
        }

        val payload = mapOf(
            "title" to title,
            "artist" to artist,
            "albumArt" to albumArt,
            "source" to source,
            "packageName" to packageName,
            "isPlaying" to isPlaying
        )

        eventSink?.success(payload)
    }

    private fun hasNotificationAccess(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        return enabledListeners.contains(context.packageName)
    }

    private fun openNotificationSettings() {
        val intent = android.content.Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }
    private fun bitmapToBase64(bitmap: Bitmap?): String? {
        if (bitmap == null) return null

        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream)
        val bytes = stream.toByteArray()

        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }
}

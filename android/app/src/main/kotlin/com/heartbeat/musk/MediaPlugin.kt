package com.heartbeat.musk

import android.content.ComponentName
import android.content.Context
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.media.MediaMetadata
import com.google.firebase.firestore.FieldValue
import com.google.type.DateTime

class MediaPlugin : FlutterPlugin, EventChannel.StreamHandler {

    private lateinit var context: Context
    private lateinit var eventChannel: EventChannel
    private lateinit var methodChannel: MethodChannel

    private var eventSink: EventChannel.EventSink? = null
    private var sessionManager: MediaSessionManager? = null
    private var activeController: MediaController? = null

    companion object {
        const val EVENT_CHANNEL = "com.nowplaying/media_events"
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
                "play" -> {
                    activeController?.transportControls?.play()
                    result.success(null)
                }

                "pause" -> {
                    activeController?.transportControls?.pause()
                    result.success(null)
                }

                "skipNext" -> {
                    activeController?.transportControls?.skipToNext()
                    result.success(null)
                }

                "skipPrevious" -> {
                    activeController?.transportControls?.skipToPrevious()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        eventChannel.setStreamHandler(null)
        methodChannel.setMethodCallHandler(null)
    }

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

    private fun startMediaSessionListener() {
        try {
            sessionManager =
                context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
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

    private fun attachController(controller: MediaController) {
        activeController?.unregisterCallback(mediaControllerCallback)
        activeController = controller
        controller.registerCallback(mediaControllerCallback)

        // Emit current state immediately
        emitCurrentState(controller)
    }

    private fun emitCurrentState(controller: MediaController) {
        val meta = controller.metadata
        val state = controller.playbackState

        if (meta != null && state != null) {
            emitMediaInfo(controller)
        }
    }

    private val mediaControllerCallback = object : MediaController.Callback() {
        override fun onMetadataChanged(metadata: MediaMetadata?) {
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

    private fun emitMediaInfo(controller: MediaController) {
        val meta = controller.metadata ?: return
        val safeMeta = meta.toSafeMap()

        val title = safeMeta["title"] as? String ?: "Unknown Title"
        val artist = safeMeta["artist"] as? String ?: "Unknown Artist"
        val albumArt = safeMeta["artwork"] as? String
        val duration = safeMeta["duration"]

        val packageName = controller.packageName ?: ""
        val state = controller.playbackState
        val isPlaying = state?.state == PlaybackState.STATE_PLAYING
        val nowMillis = System.currentTimeMillis()
        val data = mutableMapOf(
            "title" to title,
            "artist" to artist,
            "albumArt" to albumArt,
            "duration" to duration,
            "isPlaying" to isPlaying,
            "isActive" to true,
            "packageName" to packageName,
            "playbackInfo" to controller.playbackInfo.toString(),
            "updatedAt" to nowMillis,
            "source" to parseSource(packageName)
        )

        eventSink?.success(data)
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
}


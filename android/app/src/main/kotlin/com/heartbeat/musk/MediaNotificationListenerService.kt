package com.heartbeat.musk

import android.service.notification.NotificationListenerService

/**
 * This service is required as a hook for MediaSessionManager.getActiveSessions().
 * It doesn't need to process notifications — its presence and registration is
 * enough to grant media session access.
 */
class MediaNotificationListenerService : NotificationListenerService()

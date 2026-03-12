import * as functions from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();
const db = admin.firestore();

// ── Send push notification when a reaction is created ────────────────────────
export const onReactionCreated = functions.firestore.onDocumentCreated(
  'nowplaying/{uid}/reactions/{reactionId}',
  async (event) => {
    const { uid } = event.params;
    const data = event.data?.data();
    if (!data) return;

    const fromUid: string = data.fromUid;
    const emoji: string = data.emoji;

    // Get sender's display name
    const fromUserDoc = await db.collection('users').doc(fromUid).get();
    const fromName = fromUserDoc.data()?.displayName ?? 'Someone';

    // Get receiver's FCM token
    const toUserDoc = await db.collection('users').doc(uid).get();
    const fcmToken = toUserDoc.data()?.fcmToken;
    if (!fcmToken) return;

    // Get the track being reacted to
    const npDoc = await db.collection('nowplaying').doc(uid).get();
    const track = npDoc.data()?.title ?? 'your track';

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: `${emoji} ${fromName} reacted!`,
        body: `They reacted to "${track}"`,
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'nowplaying_reactions',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1 },
        },
      },
      data: {
        screen: 'feed',
        fromUid,
        emoji,
      },
    });
  }
);

// ── Cleanup stale now-playing docs (older than 6 hours) ─────────────────────
export const cleanupStaleNowPlaying = functions.scheduler.onSchedule(
  'every 6 hours',
  async () => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 6 * 60 * 60 * 1000)
    );
    const snap = await db
      .collection('nowplaying')
      .where('isActive', '==', true)
      .where('updatedAt', '<', cutoff)
      .get();

    const batch = db.batch();
    snap.docs.forEach((doc) => {
      batch.update(doc.ref, { isActive: false });
    });
    await batch.commit();
    console.log(`Cleaned up ${snap.size} stale now-playing docs.`);
  }
);

// ── On new user → send welcome notification ───────────────────────────────────
export const onNewUser = functions.firestore.onDocumentCreated(
  'users/{uid}',
  async (event) => {
    const data = event.data?.data();
    const fcmToken = data?.fcmToken;
    if (!fcmToken) return;

    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: '🎵 Welcome to NowPlaying!',
        body: 'Add friends and start sharing what you\'re listening to.',
      },
    });
  }
);

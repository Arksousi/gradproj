const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

// ── Helper ──────────────────────────────────────────────────────────────────

async function fcmToken(userId) {
  const doc = await getFirestore().collection('users').doc(userId).get();
  return doc.exists ? (doc.data().fcmToken ?? null) : null;
}

async function send(token, title, body, type, extra = {}) {
  if (!token) return;
  await getMessaging().send({
    token,
    notification: { title, body },
    data: { type, ...extra },
    android: { priority: 'high', notification: { channelId: 'psycare_high', sound: 'default' } },
    apns: { payload: { aps: { sound: 'default', badge: 1 } } },
  });
}

// ── 1. New booking request → notify therapist ────────────────────────────────

exports.onBookingCreated = onDocumentCreated('booking_requests/{id}', async (event) => {
  const data = event.data.data();
  const token = await fcmToken(data.therapistId);
  const typeLabel = { chat: 'chat', video: 'video call', 'in-person': 'in-person' }[data.sessionType] ?? 'session';
  await send(
    token,
    'New Session Request',
    `${data.patientName} wants to book a ${typeLabel} with you`,
    'booking_request',
    { bookingId: event.params.id },
  );
});

// ── 2. Booking confirmed / declined → notify patient ────────────────────────

exports.onBookingUpdated = onDocumentUpdated('booking_requests/{id}', async (event) => {
  const before = event.data.before.data();
  const after  = event.data.after.data();

  if (before.status === after.status) return;

  const therapist = after.therapistName || 'Your therapist';
  const patient   = after.patientName   || 'Your patient';

  switch (after.status) {
    case 'confirmed': {
      const token = await fcmToken(after.patientId);
      await send(token, 'Session Confirmed!',
        `${therapist} confirmed your session request`,
        'booking_update', { status: 'confirmed' });
      break;
    }
    case 'declined': {
      const token = await fcmToken(after.patientId);
      await send(token, 'Booking Update',
        `${therapist} is not available at this time`,
        'booking_update', { status: 'declined' });
      break;
    }
    case 'cancelled_by_patient': {
      const token = await fcmToken(after.therapistId);
      await send(token, 'Session Cancelled',
        `${patient} cancelled their booking`,
        'booking_update', { status: 'cancelled_by_patient' });
      break;
    }
    case 'cancelled_by_therapist': {
      const token = await fcmToken(after.patientId);
      await send(token, 'Session Cancelled',
        `${therapist} cancelled your session`,
        'booking_update', { status: 'cancelled_by_therapist' });
      break;
    }
    case 'reschedule_requested': {
      const token = await fcmToken(after.therapistId);
      const note = after.rescheduleNote ? `: "${after.rescheduleNote}"` : '';
      await send(token, 'Reschedule Requested',
        `${patient} requested a reschedule${note}`,
        'booking_update', { status: 'reschedule_requested' });
      break;
    }
  }
});

// ── 3. Immediate support request → notify all on-shift therapists ────────────

exports.onImmediateRequestCreated = onDocumentCreated('immediate_requests/{id}', async (event) => {
  const data = event.data.data();
  const patientName = data.patientName || 'A patient';

  const snap = await getFirestore()
    .collection('therapists')
    .where('isOnShift', '==', true)
    .where('isAvailableForImmediate', '==', true)
    .get();

  if (snap.empty) return;

  const tokens = (
    await Promise.all(snap.docs.map(d => fcmToken(d.id)))
  ).filter(Boolean);

  if (tokens.length === 0) return;

  await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: 'Urgent: Patient Needs Help',
      body: `${patientName} needs immediate support now`,
    },
    data: { type: 'immediate_request', requestId: event.params.id },
    android: { priority: 'high', notification: { channelId: 'psycare_high', sound: 'default' } },
    apns: { payload: { aps: { sound: 'default', badge: 1 } } },
  });
});

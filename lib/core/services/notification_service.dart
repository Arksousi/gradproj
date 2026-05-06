import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_routes.dart';

// Shared plugin instance used by both the background handler and the service.
final _bgLocal = FlutterLocalNotificationsPlugin();
const _bgChannelId = 'psycare_high';
const _bgChannelName = 'PsyCare Notifications';

/// Top-level handler — required by FCM; must be a bare top-level async function.
/// Called when the app is terminated or in the background and a data-only FCM
/// message arrives (no `notification` object). We show a local notification
/// ourselves so the therapist is never silently missed.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // flutter_local_notifications must be re-initialised in the background isolate.
  await _bgLocal.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final data = message.data;
  final type = data['type'] as String?;
  final title = data['title'] as String? ?? _defaultTitle(type);
  final body = data['body'] as String? ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    await _bgLocal.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _bgChannelId,
          _bgChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: type,
    );
  }
}

String _defaultTitle(String? type) {
  switch (type) {
    case 'red_flag':
      return '⚠️ Patient Needs Attention';
    case 'booking_request':
      return 'New Session Request';
    case 'booking_update':
      return 'Booking Update';
    case 'immediate_request':
      return 'Immediate Chat Request';
    default:
      return 'PsyCare';
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  StreamSubscription<String>? _tokenRefreshSub;

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  static const _channelId = 'psycare_high';
  static const _channelName = 'PsyCare Notifications';

  static const _androidChannel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: 'Session requests, booking updates and urgent alerts',
    importance: Importance.high,
  );

  /// Call once after Firebase.initializeApp().
  Future<void> initialize() async {
    // 1 — Request permission (iOS / Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2 — Create the Android high-importance channel
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // 3 — Initialise flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    // 4 — Register background handler (must be called before any other FCM calls)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5 — Foreground messages → show a local notification ourselves
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _showLocal(
        title: notification.title ?? 'PsyCare',
        body: notification.body ?? '',
        payload: _payloadFromData(message.data),
      );
    });

    // 6 — Tapped while app was in background (not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    // 7 — App opened from terminated state via notification tap
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleMessageTap(initial);

    // 8 — Foreground presentation on iOS (show banner + sound even when app is open)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Save (or refresh) the FCM token for [userId] in Firestore.
  Future<void> saveToken(String userId) async {
    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': newToken});
    });
  }

  /// Remove the FCM token on sign-out so the user stops receiving notifications.
  /// Sends a local push notification to the therapist when a red flag is triggered.
  /// Call this on the therapist's device via FCM (Cloud Functions handle remote push).
  /// This variant shows a local notification on the CURRENT device (therapist side).
  Future<void> sendRedFlagNotification({
    required String token,
    required String patientName,
  }) async {
    // Store the token for future use by Cloud Functions.
    // The actual push to the therapist's device is handled by the Cloud Function
    // (onBookingUpdated / red-flag trigger). Here we show a local alert if the
    // therapist happens to have the app open.
    _showLocal(
      title: '⚠️ Patient Needs Attention',
      body: '$patientName has shared something that requires your immediate attention.',
      payload: 'red_flag',
    );
  }

  Future<void> clearToken(String userId) async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _messaging.deleteToken();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'fcmToken': FieldValue.delete()});
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  void _showLocal({
    required String title,
    required String body,
    String? payload,
  }) {
    _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  void _onLocalTap(NotificationResponse response) {
    _navigate(response.payload);
  }

  void _handleMessageTap(RemoteMessage message) {
    _navigate(_payloadFromData(message.data));
  }

  void _navigate(String? payload) {
    if (payload == null) return;
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('[NotificationService] _navigate: navigator key not set or state is null (payload=$payload)');
      return;
    }

    switch (payload) {
      case 'booking_request':
        navigator.pushNamed(AppRoutes.bookingRequests);
      case 'booking_update':
        navigator.pushNamed(AppRoutes.patientDashboard);
      case 'immediate_request':
        navigator.pushNamed(AppRoutes.incomingRequests);
      case 'red_flag':
        navigator.pushNamed(AppRoutes.redFlagAlerts);
    }
  }

  String? _payloadFromData(Map<String, dynamic> data) => data['type'] as String?;

  // Lazily resolved to avoid a circular import with app.dart.
  GlobalKey<NavigatorState>? _navigatorKey;
  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }
}

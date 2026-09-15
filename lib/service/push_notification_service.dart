import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'api_service.dart';
import 'notification_service.dart';

bool get _fcmSupported =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS ||
    defaultTargetPlatform == TargetPlatform.macOS;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.notification == null && message.data.isNotEmpty) {
    final title = message.data['title']?.toString() ?? 'EduGest';
    final body =
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';
    if (body.isNotEmpty) {
      await NotificationService.instance.showNotification(
        title: title,
        message: body,
        type: message.data['type']?.toString(),
        id: message.data['notificationId']?.toString(),
      );
    }
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();
  bool _started = false;

  static Future<void> initialize() async {
    if (!_fcmSupported) return;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> start({String? userId}) async {
    if (_started || !_fcmSupported) return;
    if (userId != null && userId.isNotEmpty) {
      NotificationService.instance.start(userId: userId);
    }
    _started = true;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final token = await messaging.getToken();
      if (token != null) await _register(token);
      messaging.onTokenRefresh.listen(_register);

      FirebaseMessaging.onMessage.listen((message) async {
        final notification = message.notification;
        if (notification != null && !kIsWeb) {
          await NotificationService.instance.showNotification(
            title: notification.title ?? 'EduGest',
            message: notification.body ?? '',
            type: message.data['type']?.toString(),
            id: message.data['notificationId']?.toString(),
          );
        }
      });
    } catch (error) {
      _started = false;
      debugPrint('Erreur initialisation FCM: $error');
    }
  }

  Future<void> _register(String token) => ApiService.registerPushToken(
    token: token,
    platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
  );
}

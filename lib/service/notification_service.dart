import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  static const _pollInterval = Duration(seconds: 30);
  static const _seenKey = 'edugest_seen_notification_ids';
  static const _enabledKey = 'edugest_notifications_enabled';

  // Types de notifications gérés selon les rôles définis
  static const _importantTypes = {
    'payment', // Comptable -> Parent
    'grade', // Censeur/Enseignant -> Parent
    'absence', // Surveillant Général -> Parent
    'event', // Secrétaire/Proviseur -> Tous
    'discipline', // Surveillant/Proviseur -> Parent
  };

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  SharedPreferences? _preferences;
  bool _initialized = false;
  bool _starting = false;
  bool _polling = false;
  String? _userId;

  bool get isEnabled => _preferences?.getBool(_enabledKey) ?? true;

  Future<void> start({String? userId}) async {
    if (kIsWeb || _initialized || _starting) return;
    _userId = userId ?? _userId;
    _starting = true;

    try {
      _preferences = await SharedPreferences.getInstance();
      if (!isEnabled) return;
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const windows = WindowsInitializationSettings(
        appName: 'EduGest',
        appUserModelId: 'com.example.edugest',
        guid: '8f5bf5a4-7be4-4e7a-a6a1-4f5e4b6f2c7d',
      );
      const settings = InitializationSettings(
        android: android,
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
        windows: windows,
      );

      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      _initialized = true;
      await _poll();
      _timer = Timer.periodic(_pollInterval, (_) => _poll());
    } catch (error) {
      debugPrint('Erreur initialisation notifications: $error');
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _initialized = false;
  }

  Future<void> setEnabled(bool enabled) async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setBool(_enabledKey, enabled);
    if (enabled) {
      await start();
    } else {
      await stop();
    }
  }

  Future<void> _poll() async {
    if (!_initialized || _polling) return;
    _polling = true;
    try {
      final notifications = await ApiService.getUnreadNotifications(
        userId: _userId,
      );
      final key = '${_seenKey}_${ApiService.activeSchoolId ?? 'default'}';
      final seen = _preferences?.getStringList(key)?.toSet() ?? {};

      for (final notification in notifications.reversed) {
        final id = notification['id']?.toString();
        final type = notification['type']?.toString().toLowerCase();

        // Filtrage : On ne montre que les notifications importantes définies dans le projet
        if (id == null ||
            seen.contains(id) ||
            !_importantTypes.contains(type)) {
          continue;
        }

        await _show(notification, id);
        seen.add(id);
      }

      final values = seen.toList();
      if (values.length > 500) {
        values.removeRange(0, values.length - 500);
      }
      await _preferences?.setStringList(key, values);
    } catch (error) {
      debugPrint('Erreur synchronisation notifications: $error');
    } finally {
      _polling = false;
    }
  }

  Future<void> _show(Map<String, dynamic> notification, String id) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'edugest_alerts',
        'Alertes Scolaires',
        channelDescription:
            'Notifications pour les notes, absences et paiements',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );

    await _plugin.show(
      id.hashCode & 0x7fffffff,
      notification['title']?.toString() ?? 'EduGest',
      notification['message']?.toString() ?? '',
      details,
    );
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper over flutter_local_notifications for the one alert this app
/// fires: "the elder may have left their safe zone", shown on family devices
/// that have the app open (foreground or backgrounded, process alive).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  int _nextId = 0;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    // NOTE: init no longer asks for POST_NOTIFICATIONS. The Permissions
    // onboarding screen calls [requestPermission] at the right moment.
    _ready = true;
  }

  /// Android 13+ runtime permission. Returns true when granted (or when the
  /// platform needs no runtime grant). Safe to call repeatedly.
  Future<bool> requestPermission() async {
    try {
      if (!_ready) await init();
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<void> showSafeZoneAlert(String title, String body) async {
    if (!_ready) await init();
    const android = AndroidNotificationDetails(
      'safe_zone_alerts',
      'Safe zone alerts',
      channelDescription: 'Alerts when an elder may have left their safe zone',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _plugin.show(
      _nextId++,
      title,
      body,
      const NotificationDetails(android: android, iOS: ios),
    );
  }
}

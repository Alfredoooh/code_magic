// lib/services/notification_service_stub.dart
// Stub for web platform where Local Notifications are not available

class FlutterLocalNotificationsPlugin {
  Future<bool?> initialize(dynamic settings, {dynamic onDidReceiveNotificationResponse}) async => null;
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    dynamic scheduledDate,
    dynamic details, {
    dynamic androidScheduleMode,
    dynamic uiLocalNotificationDateInterpretation,
    String? payload,
  }) async {}
  Future<void> cancel(int id) async {}
  Future<void> cancelAll() async {}
  Future<void> show(
    int id,
    String? title,
    String? body,
    dynamic details, {
    String? payload,
  }) async {}
}

class AndroidInitializationSettings {
  AndroidInitializationSettings(String icon);
}

class DarwinInitializationSettings {
  DarwinInitializationSettings({
    bool requestAlertPermission = true,
    bool requestBadgePermission = true,
    bool requestSoundPermission = true,
  });
}

class InitializationSettings {
  InitializationSettings({dynamic android, dynamic iOS});
}

class AndroidNotificationDetails {
  AndroidNotificationDetails(
    String channelId,
    String channelName, {
    String? channelDescription,
    Importance? importance,
    Priority? priority,
    String? icon,
    dynamic color,
    bool? enableLights,
    dynamic ledColor,
    int? ledOnMs,
    int? ledOffMs,
  });
}

class DarwinNotificationDetails {
  DarwinNotificationDetails({
    bool presentAlert = true,
    bool presentBadge = true,
    bool presentSound = true,
  });
}

class NotificationDetails {
  NotificationDetails({dynamic android, dynamic iOS});
}

enum Importance { high }

enum Priority { high }

class Color {
  Color(int value);
}

enum AndroidScheduleMode { exactAllowWhileIdle }

enum UILocalNotificationDateInterpretation { absoluteTime }

class IOSFlutterLocalNotificationsPlugin {
  Future<bool?> requestPermissions({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async => null;
}
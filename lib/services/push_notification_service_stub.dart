// lib/services/push_notification_service_stub.dart
// Stub for web platform where Firebase Messaging and Local Notifications are not available

class FirebaseMessaging {
  static FirebaseMessaging get instance => FirebaseMessaging();
  Future<dynamic> requestPermission({bool alert = true, bool badge = true, bool sound = true, bool provisional = false}) async {}
  Future<String?> getToken() async => null;
  Stream<String> get onTokenRefresh => Stream.empty();
  static Stream<dynamic> get onBackgroundMessage => Stream.empty();
  static Stream<dynamic> get onMessage => Stream.empty();
  static Stream<dynamic> get onMessageOpenedApp => Stream.empty();
  Future<dynamic> getInitialMessage() async => null;
  Future<void> subscribeToTopic(String topic) async {}
  Future<void> unsubscribeFromTopic(String topic) async {}
}

class FlutterLocalNotificationsPlugin {
  Future<bool?> initialize(dynamic settings, {dynamic onDidReceiveNotificationResponse}) async => null;
  Future<void> show(int id, String? title, String? body, dynamic details, {String? payload}) async {}
}

class AndroidInitializationSettings {
  AndroidInitializationSettings(String icon);
}

class DarwinInitializationSettings {
  DarwinInitializationSettings({
    bool requestAlertPermission = false,
    bool requestBadgePermission = false,
    bool requestSoundPermission = false,
  });
}

class InitializationSettings {
  InitializationSettings({
    dynamic android,
    dynamic iOS,
  });
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
    bool? playSound,
    bool? enableVibration,
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

enum AuthorizationStatus { authorized, denied, notDetermined, provisional }

enum Importance { high }

enum Priority { high }

class Color {
  Color(int value);
}
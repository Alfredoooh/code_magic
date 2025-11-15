// lib/services/push_notification_service_stub.dart
// Stub para web - PushNotificationService não funciona no web

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  Future<void> initialize() async {
    print('⚠️ PushNotificationService stub - não disponível na web');
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('⚠️ showLocalNotification não disponível na web: $title');
  }

  Future<String?> getToken() async {
    print('⚠️ getToken não disponível na web');
    return null;
  }

  Future<void> subscribeToTopic(String topic) async {
    print('⚠️ subscribeToTopic não disponível na web: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    print('⚠️ unsubscribeFromTopic não disponível na web: $topic');
  }
}
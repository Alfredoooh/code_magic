// lib/services/notification_service_stub.dart
// Stub para web - NotificationService não funciona no web

class NotificationService {
  Future<void> initialize() async {
    print('⚠️ NotificationService stub - não disponível na web');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    print('⚠️ scheduleNotification não disponível na web: $title');
  }

  Future<void> cancelNotification(int id) async {
    print('⚠️ cancelNotification não disponível na web: $id');
  }

  Future<void> cancelAllNotifications() async {
    print('⚠️ cancelAllNotifications não disponível na web');
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    print('⚠️ showImmediateNotification não disponível na web: $title');
  }
}
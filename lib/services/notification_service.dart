// lib/services/notification_service.dart (versão corrigida, sem const em expressões não-const)
import 'package:flutter/foundation.dart' show kIsWeb;

// Imports condicionais
import 'package:flutter_local_notifications/flutter_local_notifications.dart' if (dart.library.html) 'notification_service_stub.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  dynamic _notifications;

  Future<void> initialize() async {
    if (kIsWeb) {
      print('⚠️ Notificações locais não disponíveis na web');
      return;
    }

    try {
      _notifications = FlutterLocalNotificationsPlugin();
      tz.initializeTimeZones();

      final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher'); // Removido const
      final iosSettings = DarwinInitializationSettings( // Removido const
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initSettings = InitializationSettings( // Removido const
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Solicitar permissões no iOS
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      print('❌ Erro ao inicializar notificações: $e');
    }
  }

  void _onNotificationTapped(dynamic response) {
    if (kIsWeb) return;
    print('Notificação tocada: ${response.payload}');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (kIsWeb) {
      print('⚠️ scheduleNotification não disponível na web: $title');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails( // Removido const
        'task_reminders',
        'Lembretes de Tarefas',
        channelDescription: 'Notificações para lembretes de tarefas',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF1877F2),
        enableLights: true,
        ledColor: Color(0xFF1877F2),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      final iosDetails = DarwinNotificationDetails( // Removido const
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails( // Removido const
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      print('❌ Erro ao agendar notificação: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      print('⚠️ cancelNotification não disponível na web: $id');
      return;
    }

    try {
      await _notifications.cancel(id);
    } catch (e) {
      print('❌ Erro ao cancelar notificação: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      print('⚠️ cancelAllNotifications não disponível na web');
      return;
    }

    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('❌ Erro ao cancelar todas notificações: $e');
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      print('⚠️ showImmediateNotification não disponível na web: $title');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails( // Removido const
        'immediate_notifications',
        'Notificações Imediatas',
        channelDescription: 'Notificações que aparecem imediatamente',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      final iosDetails = DarwinNotificationDetails( // Removido const
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails( // Removido const
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      print('❌ Erro ao mostrar notificação imediata: $e');
    }
  }
}
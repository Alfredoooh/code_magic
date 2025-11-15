// lib/services/push_notification_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler de background DEVE estar no nível global (fora da classe)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Background message: ${message.notification?.title}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) {
      print('⚠️ Push notifications não disponíveis na web');
      return;
    }

    // Solicitar permissões
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurar notificações locais
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // CORRIGIDO: Registrar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message: ${message.notification?.title}');
      
      if (message.notification != null) {
        showLocalNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: message.notification!.title ?? 'Notificação',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Get FCM token
    final token = await _messaging.getToken();
    print('🔑 FCM Token: $token');
  }

  // CORRIGIDO: Método público para ser usado externamente
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Notificações',
      channelDescription: 'Canal de notificações padrão',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<String?> getToken() async {
    if (kIsWeb) return null;
    return await _messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    await _messaging.unsubscribeFromTopic(topic);
  }
}
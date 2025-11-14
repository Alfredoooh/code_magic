// lib/services/push_notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

// Handler para mensagens em background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Mensagem em background: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize(String userId) async {
    // Solicitar permissões
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permissão de notificações concedida');
    } else {
      print('❌ Permissão de notificações negada');
      return;
    }

    // Configurar notificações locais
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Obter token FCM
    _fcmToken = await _messaging.getToken();
    if (_fcmToken != null) {
      print('📱 FCM Token: $_fcmToken');
      await _saveFCMToken(userId, _fcmToken!);
    }

    // Listener para atualização de token
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveFCMToken(userId, newToken);
    });

    // Configurar handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listener para mensagens em foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Listener para quando o app é aberto via notificação
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Verificar se o app foi aberto via notificação
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _saveFCMToken(String userId, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      print('✅ FCM Token salvo no Firestore');
    } catch (e) {
      print('❌ Erro ao salvar FCM Token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Mensagem recebida em foreground: ${message.messageId}');
    
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _showLocalNotification(
        id: message.messageId.hashCode,
        title: notification.title ?? 'Lembrete',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('🔔 App aberto via notificação: ${message.messageId}');
    // Implementar navegação específica baseada nos dados
    final data = message.data;
    if (data.containsKey('reminderId')) {
      // Navegar para a tela do lembrete
      print('Navegar para lembrete: ${data['reminderId']}');
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Lembretes',
      channelDescription: 'Canal para lembretes e tarefas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF1877F2),
      enableLights: true,
      ledColor: Color(0xFF1877F2),
      ledOnMs: 1000,
      ledOffMs: 500,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notificação tocada: ${response.payload}');
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      // Implementar navegação
      print('Dados da notificação: $data');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    print('✅ Inscrito no tópico: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    print('✅ Desinscrito do tópico: $topic');
  }
}

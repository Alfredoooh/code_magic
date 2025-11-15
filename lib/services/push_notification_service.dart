// lib/services/push_notification_service.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

// Imports condicionais - só carrega no mobile
import 'package:firebase_messaging/firebase_messaging.dart' if (dart.library.html) 'push_notification_service_stub.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' if (dart.library.html) 'push_notification_service_stub.dart';

// Handler para mensagens em background (só no mobile)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(dynamic message) async {
  if (!kIsWeb) {
    print('📩 Mensagem em background: ${message.messageId}');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  dynamic _messaging;
  dynamic _localNotifications;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize(String userId) async {
    if (kIsWeb) {
      print('⚠️ Push notifications não disponíveis na web');
      print('💡 Use a versão mobile para receber notificações push');
      return;
    }

    try {
      // Inicializar FirebaseMessaging (só no mobile)
      _messaging = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();

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
    } catch (e) {
      print('❌ Erro ao inicializar push notifications: $e');
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

  void _handleForegroundMessage(dynamic message) {
    if (kIsWeb) return;
    
    print('📩 Mensagem recebida em foreground: ${message.messageId}');
    final notification = message.notification;

    if (notification != null) {
      _showLocalNotification(
        id: message.messageId.hashCode,
        title: notification.title ?? 'Lembrete',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageOpenedApp(dynamic message) {
    if (kIsWeb) return;
    
    print('🔔 App aberto via notificação: ${message.messageId}');
    final data = message.data;
    if (data.containsKey('reminderId')) {
      print('Navegar para lembrete: ${data['reminderId']}');
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) {
      print('⚠️ Notificação local não disponível na web: $title');
      return;
    }

    try {
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
    } catch (e) {
      print('❌ Erro ao mostrar notificação: $e');
    }
  }

  void _onNotificationTapped(dynamic response) {
    if (kIsWeb) return;
    
    print('🔔 Notificação tocada: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        print('Dados da notificação: $data');
      } catch (e) {
        print('Erro ao decodificar payload: $e');
      }
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) {
      print('⚠️ subscribeToTopic não disponível na web: $topic');
      return;
    }
    
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Inscrito no tópico: $topic');
    } catch (e) {
      print('❌ Erro ao inscrever no tópico: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) {
      print('⚠️ unsubscribeFromTopic não disponível na web: $topic');
      return;
    }
    
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Desinscrito do tópico: $topic');
    } catch (e) {
      print('❌ Erro ao desinscrever do tópico: $e');
    }
  }
}
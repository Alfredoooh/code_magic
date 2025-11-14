// lib/models/reminder_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderType { task, custom }

class Reminder {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduledDateTime;
  final ReminderType type;
  final String? linkedTaskId; // ID da tarefa vinculada (se for reminder de task)
  final bool isCompleted;
  final bool notificationSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduledDateTime,
    this.type = ReminderType.custom,
    this.linkedTaskId,
    this.isCompleted = false,
    this.notificationSent = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'type': type.name,
      'linkedTaskId': linkedTaskId,
      'isCompleted': isCompleted,
      'notificationSent': notificationSent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Reminder.fromMap(String id, Map<String, dynamic> map) {
    return Reminder(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      scheduledDateTime: (map['scheduledDateTime'] as Timestamp).toDate(),
      type: ReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderType.custom,
      ),
      linkedTaskId: map['linkedTaskId'],
      isCompleted: map['isCompleted'] ?? false,
      notificationSent: map['notificationSent'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Reminder copyWith({
    String? title,
    String? description,
    DateTime? scheduledDateTime,
    bool? isCompleted,
    bool? notificationSent,
  }) {
    return Reminder(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      type: type,
      linkedTaskId: linkedTaskId,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationSent: notificationSent ?? this.notificationSent,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// lib/services/reminder_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reminder_model.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de todos os lembretes do usuário
  Stream<List<Reminder>> getUserReminders(String userId) {
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('scheduledDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reminder.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Stream de lembretes pendentes (não completados e não notificados)
  Stream<List<Reminder>> getPendingReminders(String userId) {
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .where('notificationSent', isEqualTo: false)
        .orderBy('scheduledDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reminder.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Stream de lembretes de hoje
  Stream<List<Reminder>> getTodayReminders(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .where('scheduledDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('scheduledDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('scheduledDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reminder.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Criar lembrete
  Future<String> createReminder(Reminder reminder) async {
    final docRef = await _firestore.collection('reminders').add(reminder.toMap());
    print('✅ Lembrete criado com ID: ${docRef.id}');
    return docRef.id;
  }

  // Atualizar lembrete
  Future<void> updateReminder(Reminder reminder) async {
    await _firestore.collection('reminders').doc(reminder.id).update(reminder.toMap());
    print('✅ Lembrete atualizado: ${reminder.id}');
  }

  // Deletar lembrete
  Future<void> deleteReminder(String reminderId) async {
    await _firestore.collection('reminders').doc(reminderId).delete();
    print('✅ Lembrete deletado: $reminderId');
  }

  // Marcar como completado
  Future<void> completeReminder(String reminderId) async {
    await _firestore.collection('reminders').doc(reminderId).update({
      'isCompleted': true,
      'updatedAt': Timestamp.now(),
    });
  }

  // Marcar notificação como enviada
  Future<void> markNotificationSent(String reminderId) async {
    await _firestore.collection('reminders').doc(reminderId).update({
      'notificationSent': true,
      'updatedAt': Timestamp.now(),
    });
  }

  // Buscar lembrete por ID da tarefa
  Future<Reminder?> getReminderByTaskId(String taskId) async {
    final snapshot = await _firestore
        .collection('reminders')
        .where('linkedTaskId', isEqualTo: taskId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Reminder.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
  }

  // Deletar lembrete por ID da tarefa
  Future<void> deleteReminderByTaskId(String taskId) async {
    final snapshot = await _firestore
        .collection('reminders')
        .where('linkedTaskId', isEqualTo: taskId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}

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

// lib/services/reminder_scheduler_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reminder_service.dart';
import 'push_notification_service.dart';
import '../models/reminder_model.dart';

class ReminderSchedulerService {
  static final ReminderSchedulerService _instance = ReminderSchedulerService._internal();
  factory ReminderSchedulerService() => _instance;
  ReminderSchedulerService._internal();

  final ReminderService _reminderService = ReminderService();
  final PushNotificationService _pushService = PushNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _checkTimer;
  StreamSubscription? _reminderSubscription;

  // Inicializar o scheduler
  void initialize(String userId) {
    print('🔔 Inicializando ReminderScheduler para user: $userId');

    // Verificar lembretes a cada 30 segundos
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkPendingReminders(userId);
    });

    // Listener em tempo real para novos lembretes
    _reminderSubscription = _reminderService
        .getPendingReminders(userId)
        .listen((reminders) {
      _processReminders(reminders);
    });

    // Verificação inicial
    _checkPendingReminders(userId);
  }

  Future<void> _checkPendingReminders(String userId) async {
    try {
      final now = DateTime.now();
      
      final snapshot = await _firestore
          .collection('reminders')
          .where('userId', isEqualTo: userId)
          .where('isCompleted', isEqualTo: false)
          .where('notificationSent', isEqualTo: false)
          .where('scheduledDateTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      for (var doc in snapshot.docs) {
        final reminder = Reminder.fromMap(doc.id, doc.data());
        await _sendReminderNotification(reminder);
        await _reminderService.markNotificationSent(reminder.id);
      }
    } catch (e) {
      print('❌ Erro ao verificar lembretes: $e');
    }
  }

  void _processReminders(List<Reminder> reminders) {
    final now = DateTime.now();
    
    for (var reminder in reminders) {
      if (reminder.scheduledDateTime.isBefore(now) && !reminder.notificationSent) {
        _sendReminderNotification(reminder);
        _reminderService.markNotificationSent(reminder.id);
      }
    }
  }

  Future<void> _sendReminderNotification(Reminder reminder) async {
    print('📨 Enviando notificação para: ${reminder.title}');
    
    await _pushService._showLocalNotification(
      id: reminder.id.hashCode,
      title: '⏰ ${reminder.title}',
      body: reminder.description ?? 'Você tem um lembrete!',
      payload: jsonEncode({
        'reminderId': reminder.id,
        'type': 'reminder',
      }),
    );
  }

  // Agendar lembrete específico
  Future<void> scheduleReminder(Reminder reminder) async {
    print('📅 Agendando lembrete: ${reminder.title} para ${reminder.scheduledDateTime}');
    
    final now = DateTime.now();
    if (reminder.scheduledDateTime.isBefore(now)) {
      // Se a data já passou, enviar imediatamente
      await _sendReminderNotification(reminder);
      await _reminderService.markNotificationSent(reminder.id);
    }
  }

  // Cancelar lembrete
  Future<void> cancelReminder(String reminderId) async {
    print('❌ Cancelando lembrete: $reminderId');
    await _reminderService.deleteReminder(reminderId);
  }

  void dispose() {
    _checkTimer?.cancel();
    _reminderSubscription?.cancel();
  }
}

import 'dart:convert';
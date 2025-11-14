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
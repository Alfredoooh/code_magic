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
// lib/services/task_service.dart - VERSÃO ATUALIZADA COM LEMBRETES
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../models/reminder_model.dart';
import 'reminder_service.dart';
import 'reminder_scheduler_service.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReminderService _reminderService = ReminderService();
  final ReminderSchedulerService _schedulerService = ReminderSchedulerService();

  Stream<List<Task>> getUserTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Task>> getTasksByPriority(String userId, TaskPriority priority) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('priority', isEqualTo: priority.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Task>> getCompletedTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<Task>> getPendingTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('isCompleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<String> createTask(Task task) async {
    final docRef = await _firestore.collection('tasks').add(task.toMap());
    print('✅ Tarefa criada com ID: ${docRef.id}');

    // Criar lembrete se hasReminder = true
    if (task.hasReminder && task.reminderDateTime != null) {
      await _createReminderForTask(docRef.id, task);
    }

    return docRef.id;
  }

  Future<void> updateTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).update(task.toMap());
    print('✅ Tarefa atualizada: ${task.id}');

    // Atualizar ou criar lembrete
    if (task.hasReminder && task.reminderDateTime != null) {
      final existingReminder = await _reminderService.getReminderByTaskId(task.id);
      
      if (existingReminder != null) {
        // Atualizar lembrete existente
        final updatedReminder = existingReminder.copyWith(
          title: task.title,
          description: task.description,
          scheduledDateTime: task.reminderDateTime,
        );
        await _reminderService.updateReminder(updatedReminder);
      } else {
        // Criar novo lembrete
        await _createReminderForTask(task.id, task);
      }
    } else {
      // Deletar lembrete se hasReminder = false
      await _reminderService.deleteReminderByTaskId(task.id);
    }
  }

  Future<void> deleteTask(String taskId) async {
    // Deletar lembrete associado
    await _reminderService.deleteReminderByTaskId(taskId);
    
    // Deletar tarefa
    await _firestore.collection('tasks').doc(taskId).delete();
    print('✅ Tarefa deletada: $taskId');
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'isCompleted': isCompleted,
      'updatedAt': Timestamp.now(),
    });

    // Se completar a tarefa, completar também o lembrete
    if (isCompleted) {
      final reminder = await _reminderService.getReminderByTaskId(taskId);
      if (reminder != null) {
        await _reminderService.completeReminder(reminder.id);
      }
    }
  }

  Future<void> _createReminderForTask(String taskId, Task task) async {
    if (task.reminderDateTime == null) return;

    final reminder = Reminder(
      id: '',
      userId: task.userId,
      title: task.title,
      description: task.description ?? 'Lembrete de tarefa',
      scheduledDateTime: task.reminderDateTime!,
      type: ReminderType.task,
      linkedTaskId: taskId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final reminderId = await _reminderService.createReminder(reminder);
    
    // Agendar notificação
    await _schedulerService.scheduleReminder(
      reminder.copyWith(id: reminderId) as Reminder,
    );
  }
}
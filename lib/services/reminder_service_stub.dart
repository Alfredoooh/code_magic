// lib/services/reminder_scheduler_service_stub.dart
// Stub para web - ReminderSchedulerService não funciona no web

class ReminderSchedulerService {
  static final ReminderSchedulerService _instance = ReminderSchedulerService._internal();
  factory ReminderSchedulerService() => _instance;
  ReminderSchedulerService._internal();

  void initialize(String userId) {
    print('⚠️ ReminderSchedulerService stub - não disponível na web');
    print('💡 userId: $userId');
  }

  Future<void> scheduleReminder(dynamic reminder) async {
    print('⚠️ scheduleReminder não disponível na web');
  }

  Future<void> cancelReminder(String reminderId) async {
    print('⚠️ cancelReminder não disponível na web: $reminderId');
  }

  void dispose() {
    print('⚠️ dispose não disponível na web');
  }
}
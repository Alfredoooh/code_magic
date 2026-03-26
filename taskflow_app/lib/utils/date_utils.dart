import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Hoje';
    if (dateOnly == tomorrow) return 'Amanhã';
    if (dateOnly == yesterday) return 'Ontem';

    return DateFormat('d MMM', 'pt_BR').format(date);
  }

  static String formatFullDate(DateTime date) {
    return DateFormat('d MMMM yyyy', 'pt_BR').format(date);
  }

  static bool isOverdue(DateTime? dueDate) {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate.isBefore(now);
  }

  static bool isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

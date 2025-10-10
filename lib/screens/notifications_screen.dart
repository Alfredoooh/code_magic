import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('notifications')!),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            onPressed: () => _markAllAsRead(userId),
            tooltip: AppLocalizations.of(context)!.translate('mark_all_read')!,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(AppLocalizations.of(context)!.translate('error_loading')!),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.translate('no_notifications')!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              final isRead = notification['read'] ?? false;

              return Dismissible(
                key: Key(notificationId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: danger,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _deleteNotification(notificationId);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: isRead ? null : accentPrimary.withOpacity(0.1),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getNotificationColor(notification['type']),
                      child: Icon(
                        _getNotificationIcon(notification['type']),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      notification['title'] ?? '',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['message'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(notification['timestamp']),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: !isRead
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: accentPrimary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(notificationId);
                      }
                      _showNotificationDetails(context, notification);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'transaction':
        return Icons.payment_rounded;
      case 'alert':
        return Icons.warning_rounded;
      case 'order':
        return Icons.shopping_cart_rounded;
      case 'system':
        return Icons.info_rounded;
      case 'security':
        return Icons.security_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'transaction':
        return success;
      case 'alert':
        return warning;
      case 'order':
        return accentPrimary;
      case 'system':
        return info;
      case 'security':
        return danger;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final DateTime dateTime = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.parse(timestamp.toString());
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> _markAllAsRead(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final notifications = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  Future<void> _deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  void _showNotificationDetails(BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title'] ?? ''),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? ''),
            if (notification['details'] != null) ...[
              const SizedBox(height: 16),
              Text(
                notification['details'],
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.translate('close')!),
          ),
        ],
      ),
    );
  }
}
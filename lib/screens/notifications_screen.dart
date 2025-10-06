// lib/screens/notifications_screen.dart
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

/// Tela de Notificações (somente leitura; estatísticas vindas do JSON)
/// Passa opcionalmente dataUrl para apontar para a tua API:
///   NotificationsScreen(dataUrl: 'https://.../notifications.json')
class NotificationsScreen extends StatefulWidget {
  final String dataUrl;

  const NotificationsScreen({
    Key? key,
    this.dataUrl = 'https://alfredoooh.github.io/database/data/notifications.json',
  }) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resp = await http.get(Uri.parse(widget.dataUrl));
      if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
      final dynamic body = jsonDecode(resp.body);

      // Expect either a list or an object with "items"
      final List<dynamic> rawList = body is List
          ? body
          : (body['items'] is List ? body['items'] as List<dynamic> : []);

      final parsed = rawList.map<NotificationItem?>((raw) {
        try {
          final map = raw as Map<String, dynamic>;
          final id = (map['id'] ?? map['notificationId'] ?? map['uid'] ?? '').toString();
          final title = (map['title'] ?? '-').toString();
          final message = (map['message'] ?? map['body'] ?? '').toString();
          final tsRaw = map['timestamp'] ?? map['time'] ?? map['createdAt'];
          DateTime timestamp;

          if (tsRaw == null) {
            timestamp = DateTime.now();
          } else if (tsRaw is int) {
            // epoch ms or s (detect)
            if (tsRaw > 9999999999) {
              timestamp = DateTime.fromMillisecondsSinceEpoch(tsRaw);
            } else {
              timestamp = DateTime.fromMillisecondsSinceEpoch(tsRaw * 1000);
            }
          } else if (tsRaw is String) {
            timestamp = DateTime.tryParse(tsRaw) ?? DateTime.now();
          } else {
            timestamp = DateTime.now();
          }

          final isRead = (map['isRead'] ?? map['read'] ?? false) == true;
          final isArchived = (map['isArchived'] ?? map['archived'] ?? false) == true;

          return NotificationItem(
            id: id.isNotEmpty ? id : UniqueKey().toString(),
            title: title,
            message: message,
            timestamp: timestamp,
            isRead: isRead,
            isArchived: isArchived,
          );
        } catch (_) {
          return null;
        }
      }).whereType<NotificationItem>().toList();

      // sort by newest first
      parsed.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _notifications = parsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar notificações: $e';
        _isLoading = false;
      });
    }
  }

  // estatísticas baseadas no payload (sem permitir alterações locais)
  List<NotificationItem> get _newNotifications =>
      _notifications.where((n) => !n.isRead && !n.isArchived).toList();

  List<NotificationItem> get _unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationItem> get _archivedNotifications =>
      _notifications.where((n) => n.isArchived).toList();

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTimestampRelative(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    if (diff.inDays < 7) return 'Há ${diff.inDays}d';
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }

  String _formatTimestampFull(DateTime timestamp) =>
      DateFormat('EEEE, d MMMM yyyy • HH:mm', 'pt_BR').format(timestamp);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF000000),
        border: null,
        middle: const Text(
          'Notificações',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Color(0xFF007AFF)),
        ),
        // troquei "Limpar" por "Atualizar" para respeitar o modo somente-leitura
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _fetchNotifications,
          child: const Icon(CupertinoIcons.refresh, color: Color(0xFFFFFFFF)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton('Novas', 0, _newNotifications.length)),
                  Expanded(child: _buildTabButton('Não Lidas', 1, _unreadNotifications.length)),
                  Expanded(child: _buildTabButton('Arquivo', 2, _archivedNotifications.length)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, int index, int count) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.animateTo(index)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF48484A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF8E8E93),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF48484A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator(radius: 16, color: Color(0xFF007AFF)));
    }

    if (_error != null) {
      return _buildError();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildNotificationsList(_newNotifications),
        _buildNotificationsList(_unreadNotifications),
        _buildNotificationsList(_archivedNotifications),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 64, color: Color(0xFFFF3B30)),
          const SizedBox(height: 16),
          const Text('Não foi possível carregar notificações.',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_error ?? '', style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          CupertinoButton.filled(onPressed: _fetchNotifications, child: const Text('Tentar novamente')),
        ]),
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> list) {
    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final n = list[index];
        return _buildNotificationCard(n);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Color(0xFF1C1C1E), shape: BoxShape.circle),
          child: Icon(CupertinoIcons.bell_slash_fill, size: 48, color: Colors.white.withOpacity(0.3)),
        ),
        const SizedBox(height: 20),
        Text('Nenhuma notificação', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Você está em dia!', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 15)),
      ]),
    );
  }

  Widget _buildNotificationCard(NotificationItem n) {
    // cartão somente leitura — ao tocar abre detalhe (sem marcar leitura)
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (ctx) => NotificationDetailScreen(notification: n),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(
                    n.title,
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                    ),
                  ),
                ),
                if (!n.isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF007AFF), shape: BoxShape.circle),
                  ),
              ]),
              const SizedBox(height: 6),
              Text(
                n.message,
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14, height: 1.4),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                _formatTimestampRelative(n.timestamp),
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Detalhe (somente leitura) — sem ações de apagar/marcar/arquivar
class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailScreen({Key? key, required this.notification}) : super(key: key);

  String _formatFull(DateTime ts) => DateFormat('EEEE, d MMMM yyyy • HH:mm', 'pt_BR').format(ts);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF000000),
        border: null,
        middle: const Text('Detalhes', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17, fontWeight: FontWeight.w600)),
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: const Icon(CupertinoIcons.back, color: Color(0xFF007AFF))),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            Text(notification.title, style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_formatFull(notification.timestamp), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Text(notification.message, style: const TextStyle(color: Color(0xFFE5E5EA), fontSize: 17, height: 1.6)),
            ),
            const SizedBox(height: 18),
            // indicação de origem / estado (informativo apenas)
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(8)), child: Text(notification.isArchived ? 'Arquivado' : 'Ativo', style: TextStyle(color: Colors.white.withOpacity(0.9)))),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(8)), child: Text(notification.isRead ? 'Lida' : 'Não lida', style: TextStyle(color: Colors.white.withOpacity(0.9)))),
              const Spacer(),
              const Text('Fonte: API', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
            ]),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

/// Modelo de Notificação (compatível com JSON remoto)
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final bool isArchived;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.isArchived = false,
  });
}
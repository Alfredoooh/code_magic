// lib/widgets/request_cards.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/document_template_model.dart';
import 'custom_icons.dart';

class _RequestCard extends StatelessWidget {
  final DocumentRequest request;
  final Color cardColor;
  final Color textColor;
  final Color hintColor;

  const _RequestCard({
    required this.request,
    required this.cardColor,
    required this.textColor,
    required this.hintColor,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA000);
      case 'in_progress':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'in_progress':
        return 'Em andamento';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(request.status);
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          request.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              request.templateName,
              style: TextStyle(
                fontSize: 13,
                color: hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusLabel(request.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(request.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: hintColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _RequestDetailDialog(
              request: request,
              cardColor: cardColor,
              textColor: textColor,
              hintColor: hintColor,
            ),
          );
        },
      ),
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  final DocumentRequest request;
  final Color cardColor;
  final Color textColor;
  final Color hintColor;
  final Function(String status, String? notes) onStatusUpdate;
  final VoidCallback onDelete;

  const _AdminRequestCard({
    required this.request,
    required this.cardColor,
    required this.textColor,
    required this.hintColor,
    required this.onStatusUpdate,
    required this.onDelete,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA000);
      case 'in_progress':
        return const Color(0xFF2196F3);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          request.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${request.userName} • ${request.userEmail}',
              style: TextStyle(fontSize: 13, color: hintColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Template: ${request.templateName}',
              style: TextStyle(fontSize: 12, color: hintColor),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              onDelete();
            } else {
              await onStatusUpdate(value, null);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'in_progress', child: Text('Em andamento')),
            const PopupMenuItem(value: 'completed', child: Text('Concluído')),
            const PopupMenuItem(value: 'cancelled', child: Text('Cancelar')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestDetailDialog extends StatelessWidget {
  final DocumentRequest request;
  final Color cardColor;
  final Color textColor;
  final Color hintColor;

  const _RequestDetailDialog({
    required this.request,
    required this.cardColor,
    required this.textColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(request.title, style: TextStyle(color: textColor)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Template: ${request.templateName}', style: TextStyle(color: textColor)),
            const SizedBox(height: 8),
            Text('Descrição:', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(request.description, style: TextStyle(color: hintColor)),
            const SizedBox(height: 12),
            Text('Status: ${request.status}', style: TextStyle(color: textColor)),
            if (request.adminNotes != null) ...[
              const SizedBox(height: 8),
              Text('Notas do admin:', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
              Text(request.adminNotes!, style: TextStyle(color: hintColor)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
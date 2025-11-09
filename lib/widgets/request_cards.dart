// lib/widgets/request_cards.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/document_template_model.dart';
import 'custom_icons.dart';

class RequestCard extends StatelessWidget {
  final DocumentRequest request;
  final Color cardColor;
  final Color textColor;
  final Color hintColor;

  const RequestCard({
    super.key,
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

  Color _getCardColor(String status, bool isDark) {
    switch (status) {
      case 'pending':
        return isDark ? const Color(0xFF2D2416) : const Color(0xFFFFF8E1);
      case 'in_progress':
        return isDark ? const Color(0xFF1A2332) : const Color(0xFFE3F2FD);
      case 'completed':
        return isDark ? const Color(0xFF1B2E1F) : const Color(0xFFE8F5E9);
      case 'cancelled':
        return isDark ? const Color(0xFF2E1C1C) : const Color(0xFFFFEBEE);
      default:
        return cardColor;
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final statusColor = _getStatusColor(request.status);
    final bgColor = _getCardColor(request.status, isDark);
    final statusIcon = _getStatusIcon(request.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RequestDetailScreen(
                  request: request,
                  cardColor: cardColor,
                  textColor: textColor,
                  hintColor: hintColor,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            request.templateName,
                            style: TextStyle(
                              fontSize: 14,
                              color: hintColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusLabel(request.status),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: hintColor.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(request.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: hintColor.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminRequestCard extends StatelessWidget {
  final DocumentRequest request;
  final Color cardColor;
  final Color textColor;
  final Color hintColor;
  final Function(String status, String? notes) onStatusUpdate;
  final VoidCallback onDelete;

  const AdminRequestCard({
    super.key,
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

  Color _getCardColor(String status, bool isDark) {
    switch (status) {
      case 'pending':
        return isDark ? const Color(0xFF2D2416) : const Color(0xFFFFF8E1);
      case 'in_progress':
        return isDark ? const Color(0xFF1A2332) : const Color(0xFFE3F2FD);
      case 'completed':
        return isDark ? const Color(0xFF1B2E1F) : const Color(0xFFE8F5E9);
      case 'cancelled':
        return isDark ? const Color(0xFF2E1C1C) : const Color(0xFFFFEBEE);
      default:
        return cardColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final statusColor = _getStatusColor(request.status);
    final bgColor = _getCardColor(request.status, isDark);
    final statusIcon = _getStatusIcon(request.status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.2) 
                : Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RequestDetailScreen(
                  request: request,
                  cardColor: cardColor,
                  textColor: textColor,
                  hintColor: hintColor,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            request.userName,
                            style: TextStyle(
                              fontSize: 14,
                              color: hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            request.userEmail,
                            style: TextStyle(
                              fontSize: 13,
                              color: hintColor.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: textColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: cardColor,
                      onSelected: (value) async {
                        if (value == 'delete') {
                          onDelete();
                        } else {
                          await onStatusUpdate(value, null);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'in_progress',
                          child: Row(
                            children: [
                              const Icon(Icons.autorenew, size: 18, color: Color(0xFF2196F3)),
                              const SizedBox(width: 8),
                              Text('Em andamento', style: TextStyle(color: textColor)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'completed',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, size: 18, color: Color(0xFF4CAF50)),
                              const SizedBox(width: 8),
                              Text('Concluído', style: TextStyle(color: textColor)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'cancelled',
                          child: Row(
                            children: [
                              const Icon(Icons.cancel, size: 18, color: Color(0xFFF44336)),
                              const SizedBox(width: 8),
                              Text('Cancelar', style: TextStyle(color: textColor)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, size: 18, color: Colors.red),
                              const SizedBox(width: 8),
                              const Text('Excluir', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? Colors.white.withOpacity(0.05) 
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Template: ${request.templateName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: hintColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(request.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: hintColor.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RequestDetailScreen extends StatelessWidget {
  final DocumentRequest request;
  final Color cardColor;
  final Color textColor;
  final Color hintColor;

  const RequestDetailScreen({
    super.key,
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final statusColor = _getStatusColor(request.status);
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          // ✅ CORREÇÃO: Usar SvgIcon ao invés de Icon direto com CustomIcons
          icon: SvgPicture.string(
            CustomIcons.arrowLeft,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detalhes da Solicitação',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(request.status),
                      color: statusColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusLabel(request.status),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Template',
              request.templateName,
              Icons.description,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Descrição',
              request.description,
              Icons.text_snippet,
              isDark,
            ),
            if (request.adminNotes != null) ...[
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Notas do Admin',
                request.adminNotes!,
                Icons.admin_panel_settings,
                isDark,
                const Color(0xFF2196F3),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.2) 
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: hintColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Criado em: ${_formatDate(request.createdAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    bool isDark, [
    Color? accentColor,
  ]) {
    final Color sectionColor = accentColor ?? textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark 
                  ? Colors.black.withOpacity(0.2) 
                  : Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: sectionColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: sectionColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hintColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: hintColor,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
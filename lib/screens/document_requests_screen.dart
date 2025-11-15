// lib/screens/document_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../widgets/custom_icons.dart';
import 'new_request_screen.dart';
import 'request_detail_screen.dart';

enum CardLayout { list, grid, compact }

class DocumentRequestsScreen extends StatefulWidget {
  const DocumentRequestsScreen({super.key});

  @override
  State<DocumentRequestsScreen> createState() => _DocumentRequestsScreenState();
}

class _DocumentRequestsScreenState extends State<DocumentRequestsScreen> {
  final DocumentService _documentService = DocumentService();
  CardLayout _currentLayout = CardLayout.list;

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
        return const Color(0xFF8E8E93);
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
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return 'Há ${diff.inDays} dias';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String? _extractUrlFromError(Object? error) {
    if (error == null) return null;
    try {
      final s = error.toString();
      final urlRegex = RegExp(r'https?://\S+');
      final match = urlRegex.firstMatch(s);
      return match?.group(0);
    } catch (_) {
      return null;
    }
  }

  Widget _buildErrorWidget(BuildContext context, Object error, bool isDark) {
    final url = _extractUrlFromError(error);
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(
              CustomIcons.warning,
              width: 64,
              height: 64,
              colorFilter: const ColorFilter.mode(
                Colors.orange,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Índice necessário',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'O Firestore precisa criar índices para esta consulta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: secondaryColor,
              ),
            ),
            if (url != null) ...[
              const SizedBox(height: 24),
              SelectableText(
                url,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1877F2),
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copiado!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (_) {}
                },
                icon: SvgPicture.string(
                  CustomIcons.copy,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                label: const Text('Copiar link do índice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Cole no navegador e crie o índice no Console do Firebase.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final auth = context.watch<AuthProvider>();

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    if (auth.user == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder<List<DocumentRequest>>(
        stream: _documentService.getUserRequests(auth.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(context, snapshot.error!, isDark);
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return const SizedBox.shrink();
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pedidos Recentes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_currentLayout == CardLayout.list)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final request = requests[index];
                        return _RequestListCard(
                          request: request,
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RequestDetailScreen(request: request),
                              ),
                            );
                          },
                        );
                      },
                      childCount: requests.length,
                    ),
                  ),
                )
              else if (_currentLayout == CardLayout.grid)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final request = requests[index];
                        return _RequestGridCard(
                          request: request,
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RequestDetailScreen(request: request),
                              ),
                            );
                          },
                        );
                      },
                      childCount: requests.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final request = requests[index];
                        return _RequestCompactCard(
                          request: request,
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RequestDetailScreen(request: request),
                              ),
                            );
                          },
                        );
                      },
                      childCount: requests.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: OpenContainer(
        transitionType: ContainerTransitionType.fade,
        openBuilder: (context, _) => const NewRequestScreen(),
        closedElevation: 6,
        closedShape: const CircleBorder(),
        closedColor: const Color(0xFF1877F2),
        closedBuilder: (context, openContainer) => Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFF1877F2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.string(
              CustomIcons.add,
              width: 28,
              height: 28,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Card List Layout
class _RequestListCard extends StatelessWidget {
  final DocumentRequest request;
  final bool isDark;
  final VoidCallback onTap;

  const _RequestListCard({
    required this.request,
    required this.isDark,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFFFA000);
      case 'in_progress': return const Color(0xFF2196F3);
      case 'completed': return const Color(0xFF4CAF50);
      case 'cancelled': return const Color(0xFFF44336);
      default: return const Color(0xFF8E8E93);
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'Pendente';
      case 'in_progress': return 'Em andamento';
      case 'completed': return 'Concluído';
      case 'cancelled': return 'Cancelado';
      default: return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return 'Hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return 'Há ${diff.inDays} dias';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String _getCategoryIcon(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.curriculum: return CustomIcons.person;
      case DocumentCategory.certificate: return CustomIcons.certificate;
      case DocumentCategory.letter: return CustomIcons.envelope;
      case DocumentCategory.report: return CustomIcons.description;
      case DocumentCategory.contract: return CustomIcons.contract;
      case DocumentCategory.invoice: return CustomIcons.invoice;
      case DocumentCategory.presentation: return CustomIcons.presentation;
      case DocumentCategory.essay: return CustomIcons.school;
      case DocumentCategory.other: return CustomIcons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B);
    final statusColor = _getStatusColor(request.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SvgPicture.string(
                    _getCategoryIcon(request.category),
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1877F2),
                      BlendMode.srcIn,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(request.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(request.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (request.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  request.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Card Grid Layout
class _RequestGridCard extends StatelessWidget {
  final DocumentRequest request;
  final bool isDark;
  final VoidCallback onTap;

  const _RequestGridCard({
    required this.request,
    required this.isDark,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFFFA000);
      case 'in_progress': return const Color(0xFF2196F3);
      case 'completed': return const Color(0xFF4CAF50);
      case 'cancelled': return const Color(0xFFF44336);
      default: return const Color(0xFF8E8E93);
    }
  }

  String _getCategoryIcon(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.curriculum: return CustomIcons.person;
      case DocumentCategory.certificate: return CustomIcons.certificate;
      case DocumentCategory.letter: return CustomIcons.envelope;
      case DocumentCategory.report: return CustomIcons.description;
      case DocumentCategory.contract: return CustomIcons.contract;
      case DocumentCategory.invoice: return CustomIcons.invoice;
      case DocumentCategory.presentation: return CustomIcons.presentation;
      case DocumentCategory.essay: return CustomIcons.school;
      case DocumentCategory.other: return CustomIcons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final statusColor = _getStatusColor(request.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: SvgPicture.string(
                  _getCategoryIcon(request.category),
                  width: 48,
                  height: 48,
                  colorFilter: ColorFilter.mode(statusColor, BlendMode.srcIn),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        request.status == 'pending'
                            ? 'Pendente'
                            : request.status == 'in_progress'
                                ? 'Andamento'
                                : request.status == 'completed'
                                    ? 'Concluído'
                                    : 'Cancelado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Card Compact Layout
class _RequestCompactCard extends StatelessWidget {
  final DocumentRequest request;
  final bool isDark;
  final VoidCallback onTap;

  const _RequestCompactCard({
    required this.request,
    required this.isDark,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFFFA000);
      case 'in_progress': return const Color(0xFF2196F3);
      case 'completed': return const Color(0xFF4CAF50);
      case 'cancelled': return const Color(0xFFF44336);
      default: return const Color(0xFF8E8E93);
    }
  }

  String _getCategoryIcon(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.curriculum: return CustomIcons.person;
      case DocumentCategory.certificate: return CustomIcons.certificate;
      case DocumentCategory.letter: return CustomIcons.envelope;
      case DocumentCategory.report: return CustomIcons.description;
      case DocumentCategory.contract: return CustomIcons.contract;
      case DocumentCategory.invoice: return CustomIcons.invoice;
      case DocumentCategory.presentation: return CustomIcons.presentation;
      case DocumentCategory.essay: return CustomIcons.school;
      case DocumentCategory.other: return CustomIcons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final statusColor = _getStatusColor(request.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            SvgPicture.string(
              _getCategoryIcon(request.category),
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF1877F2),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                request.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
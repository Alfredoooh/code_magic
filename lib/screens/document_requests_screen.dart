// lib/screens/document_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../widgets/custom_icons.dart';
import 'new_request_screen.dart';
import 'request_detail_screen.dart';

class DocumentRequestsScreen extends StatefulWidget {
  const DocumentRequestsScreen({super.key});

  @override
  State<DocumentRequestsScreen> createState() => _DocumentRequestsScreenState();
}

class _DocumentRequestsScreenState extends State<DocumentRequestsScreen> {
  final DocumentService _documentService = DocumentService();

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
      return 'Hoje ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} dias atrás';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Tenta extrair um URL de uma mensagem de erro (por ex. link de criação de índice do Firebase)
  String? _extractUrlFromError(Object? error) {
    if (error == null) return null;
    try {
      final s = error.toString();
      final urlRegex = RegExp(r'https?://[^\s\)\'\"]+');
      final match = urlRegex.firstMatch(s);
      return match?.group(0);
    } catch (_) {
      return null;
    }
  }

  /// Widget que mostra erro e, se houver, o link que permite criar índice no console
  Widget _buildErrorWidget(BuildContext context, Object error, bool isDark, String textColorHex) {
    final url = _extractUrlFromError(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar pedidos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().length > 200 ? '${error.toString().substring(0, 200)}...' : error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 16),
            if (url != null) ...[
              SelectableText(
                url,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF1877F2),
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado para a área de transferência')));
                    }
                  } catch (_) {
                    // sem ação adicional
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar link do índice'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Cole esse link no navegador e crie o índice no Console do Firebase (Firestore → Indexes).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
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
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    if (auth.user == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text(
            'Faça login para ver seus pedidos',
            style: TextStyle(color: textColor),
          ),
        ),
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
            return _buildErrorWidget(context, snapshot.error!, isDark, '');
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                    ),
                    child: SvgPicture.string(
                      CustomIcons.description,
                      width: 80,
                      height: 80,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1877F2),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Nenhum pedido ainda',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Crie seu primeiro pedido de documento tocando no botão abaixo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final statusColor = _getStatusColor(request.status);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestDetailScreen(request: request),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black26 
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status badge no topo
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getStatusLabel(request.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ícone da categoria
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.string(
                              _getCategoryIcon(request.category),
                              width: 40,
                              height: 40,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF1877F2),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Informações
                      Padding(
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
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                SvgPicture.string(
                                  CustomIcons.accessTime,
                                  width: 12,
                                  height: 12,
                                  colorFilter: ColorFilter.mode(
                                    isDark 
                                        ? const Color(0xFF8E8E93) 
                                        : const Color(0xFF8E8E93),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatDate(request.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark 
                                          ? const Color(0xFF8E8E93) 
                                          : const Color(0xFF8E8E93),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NewRequestScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF1877F2),
        elevation: 4,
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
    );
  }

  String _getCategoryIcon(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.curriculum:
        return CustomIcons.person;
      case DocumentCategory.certificate:
        return CustomIcons.certificate;
      case DocumentCategory.letter:
        return CustomIcons.envelope;
      case DocumentCategory.report:
        return CustomIcons.description;
      case DocumentCategory.contract:
        return CustomIcons.contract;
      case DocumentCategory.invoice:
        return CustomIcons.invoice;
      case DocumentCategory.presentation:
        return CustomIcons.presentation;
      case DocumentCategory.essay:
        return CustomIcons.school;
      case DocumentCategory.other:
        return CustomIcons.folder;
    }
  }
}
// lib/screens/document_request_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../widgets/custom_icons.dart';

class DocumentRequestDetailScreen extends StatefulWidget {
  final DocumentTemplate template;

  const DocumentRequestDetailScreen({super.key, required this.template});

  @override
  State<DocumentRequestDetailScreen> createState() => _DocumentRequestDetailScreenState();
}

class _DocumentRequestDetailScreenState extends State<DocumentRequestDetailScreen> {
  final DocumentService _documentService = DocumentService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'normal';
  bool _isSubmitting = false;

  final List<Map<String, String>> _priorities = [
    {'value': 'low', 'label': 'Baixa', 'color': '0xFF4CAF50'},
    {'value': 'normal', 'label': 'Normal', 'color': '0xFF2196F3'},
    {'value': 'high', 'label': 'Alta', 'color': '0xFFFF9800'},
    {'value': 'urgent', 'label': 'Urgente', 'color': '0xFFF44336'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_titleController.text.trim().isEmpty || 
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) {
        throw Exception('Usuário não autenticado');
      }

      final request = DocumentRequest(
        id: '',
        userId: auth.user!.uid,
        userName: auth.user!.displayName ?? 'Usuário',
        userEmail: auth.user!.email ?? '',
        templateId: widget.template.id,
        templateName: widget.template.name,
        category: widget.template.category,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        createdAt: DateTime.now(),
      );

      await _documentService.createRequest(request);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.arrowLeft,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Novo Pedido',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      widget.template.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF0F2F5),
                          child: Center(
                            child: SvgPicture.string(
                              CustomIcons.image,
                              width: 64,
                              height: 64,
                              colorFilter: ColorFilter.mode(
                                isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.template.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.template.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Título do Pedido',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Ex: Currículo para vaga de desenvolvedor',
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF242526) : const Color(0xFFF0F2F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Prioridade',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _priorities.map((priority) {
                      final isSelected = priority['value'] == _selectedPriority;
                      final color = Color(int.parse(priority['color']!));
                      return ChoiceChip(
                        label: Text(priority['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedPriority = priority['value']!);
                          }
                        },
                        selectedColor: color,
                        backgroundColor: isDark ? const Color(0xFF242526) : const Color(0xFFF0F2F5),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Descrição Detalhada',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(color: textColor),
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Descreva os detalhes do documento que você precisa...',
                      hintStyle: TextStyle(
                        color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF242526) : const Color(0xFFF0F2F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: const Color(0xFF1877F2).withOpacity(0.5),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.string(
                                  CustomIcons.send,
                                  width: 20,
                                  height: 20,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Enviar Pedido',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

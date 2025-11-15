// lib/screens/edit_request_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/theme_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../widgets/custom_icons.dart';

enum TextStyle { normal, bold, italic, underline }

class EditRequestScreen extends StatefulWidget {
  final DocumentRequest request;

  const EditRequestScreen({super.key, required this.request});

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  final DocumentService _documentService = DocumentService();
  final Map<String, TextEditingController> _fieldControllers = {};
  final TextEditingController _additionalNotesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _attachedImages = [];
  
  bool _isUpdating = false;
  int _currentFieldIndex = 0;
  String _searchQuery = '';
  final Set<TextStyle> _activeStyles = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.request.customFields != null) {
      for (var entry in widget.request.customFields!.entries) {
        _fieldControllers[entry.key] = TextEditingController(text: entry.value);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    _additionalNotesController.dispose();
    super.dispose();
  }

  List<String> _getCategoryFields(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.curriculum:
        return ['Nome Completo', 'Email', 'Telefone', 'Formação Acadêmica', 'Experiência Profissional', 'Habilidades'];
      case DocumentCategory.certificate:
        return ['Nome do Participante', 'Nome do Curso/Evento', 'Carga Horária', 'Data de Conclusão', 'Instituição'];
      case DocumentCategory.letter:
        return ['Destinatário', 'Remetente', 'Assunto', 'Saudação', 'Conteúdo Principal'];
      case DocumentCategory.report:
        return ['Título do Relatório', 'Autor', 'Departamento', 'Período Analisado', 'Resumo Executivo'];
      case DocumentCategory.contract:
        return ['Contratante', 'Contratado', 'Objeto do Contrato', 'Valor', 'Prazo', 'Cláusulas Específicas'];
      case DocumentCategory.invoice:
        return ['Número da Fatura', 'Cliente', 'Data de Emissão', 'Itens/Serviços', 'Valor Total', 'Forma de Pagamento'];
      case DocumentCategory.presentation:
        return ['Título da Apresentação', 'Autor', 'Data', 'Público-Alvo', 'Número de Slides', 'Tópicos Principais'];
      case DocumentCategory.essay:
        return ['Título do Trabalho', 'Autor', 'Curso/Disciplina', 'Professor Orientador', 'Instituição', 'Tema Central'];
      case DocumentCategory.other:
        return ['Título', 'Descrição Geral'];
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty && mounted) {
        setState(() {
          _attachedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagens: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  void _toggleTextStyle(TextStyle style) {
    setState(() {
      if (_activeStyles.contains(style)) {
        _activeStyles.remove(style);
      } else {
        _activeStyles.add(style);
      }
    });
  }

  TextStyle _getTextStyleDecoration() {
    FontWeight weight = _activeStyles.contains(TextStyle.bold) ? FontWeight.bold : FontWeight.normal;
    FontStyle style = _activeStyles.contains(TextStyle.italic) ? FontStyle.italic : FontStyle.normal;
    TextDecoration decoration = _activeStyles.contains(TextStyle.underline) 
        ? TextDecoration.underline 
        : TextDecoration.none;

    return TextStyle(
      fontWeight: weight,
      fontStyle: style,
      decoration: decoration,
    );
  }

  Future<void> _update() async {
    final fields = _getCategoryFields(widget.request.category);
    final missingFields = <String>[];
    
    for (var field in fields) {
      final controller = _fieldControllers[field];
      if (controller == null || controller.text.trim().isEmpty) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preencha os campos: ${missingFields.join(', ')}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final fieldsData = <String, String>{};
      for (var field in fields) {
        fieldsData[field] = _fieldControllers[field]!.text.trim();
      }

      final updatedRequest = DocumentRequest(
        id: widget.request.id,
        userId: widget.request.userId,
        userName: widget.request.userName,
        userEmail: widget.request.userEmail,
        templateId: widget.request.templateId,
        templateName: widget.request.templateName,
        category: widget.request.category,
        title: widget.request.title,
        description: widget.request.description,
        priority: widget.request.priority,
        status: widget.request.status,
        createdAt: widget.request.createdAt,
        updatedAt: DateTime.now(),
        adminNotes: widget.request.adminNotes,
        customFields: fieldsData,
      );

      await _documentService.updateRequest(updatedRequest);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  List<String> _getFilteredFields() {
    final allFields = _getCategoryFields(widget.request.category);
    if (_searchQuery.isEmpty) return allFields;
    return allFields
        .where((field) => field.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B);
    
    final fields = _getFilteredFields();
    
    // Garante que os controllers existam
    for (var field in _getCategoryFields(widget.request.category)) {
      if (!_fieldControllers.containsKey(field)) {
        _fieldControllers[field] = TextEditingController();
      }
    }

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
          'Editor Avançado',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.string(
              CustomIcons.search,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    'Buscar Campo',
                    style: TextStyle(color: textColor),
                  ),
                  content: TextField(
                    autofocus: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Digite o nome do campo...',
                      hintStyle: TextStyle(color: secondaryColor),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      Navigator.pop(ctx);
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancelar', style: TextStyle(color: secondaryColor)),
                    ),
                  ],
                ),
              );
            },
          ),
          if (!_isUpdating)
            TextButton(
              onPressed: _update,
              child: const Text(
                'Salvar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1877F2),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de ferramentas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Navegação de campos
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 16),
                          color: const Color(0xFF1877F2),
                          onPressed: _currentFieldIndex > 0
                              ? () {
                                  setState(() => _currentFieldIndex--);
                                }
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                        Text(
                          '${_currentFieldIndex + 1}/${fields.length}',
                          style: const TextStyle(
                            color: Color(0xFF1877F2),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16),
                          color: const Color(0xFF1877F2),
                          onPressed: _currentFieldIndex < fields.length - 1
                              ? () {
                                  setState(() => _currentFieldIndex++);
                                }
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Formatação de texto
                  _ToolbarButton(
                    icon: Icons.format_bold,
                    isActive: _activeStyles.contains(TextStyle.bold),
                    onPressed: () => _toggleTextStyle(TextStyle.bold),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    icon: Icons.format_italic,
                    isActive: _activeStyles.contains(TextStyle.italic),
                    onPressed: () => _toggleTextStyle(TextStyle.italic),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    icon: Icons.format_underline,
                    isActive: _activeStyles.contains(TextStyle.underline),
                    onPressed: () => _toggleTextStyle(TextStyle.underline),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),

                  // Adicionar imagens
                  _ToolbarButton(
                    icon: Icons.image,
                    isActive: false,
                    onPressed: _pickImages,
                    isDark: isDark,
                    label: 'Imagens',
                  ),
                  const SizedBox(width: 8),

                  // Limpar campo
                  _ToolbarButton(
                    icon: Icons.clear,
                    isActive: false,
                    onPressed: () {
                      if (fields.isNotEmpty && _currentFieldIndex < fields.length) {
                        final field = fields[_currentFieldIndex];
                        _fieldControllers[field]?.clear();
                      }
                    },
                    isDark: isDark,
                    label: 'Limpar',
                  ),
                  const SizedBox(width: 8),

                  // Desfazer
                  _ToolbarButton(
                    icon: Icons.undo,
                    isActive: false,
                    onPressed: () {
                      // Implementar desfazer
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),

                  // Refazer
                  _ToolbarButton(
                    icon: Icons.redo,
                    isActive: false,
                    onPressed: () {
                      // Implementar refazer
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),

          // Imagens anexadas
          if (_attachedImages.isNotEmpty) ...[
            Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _attachedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],

          // Área de edição
          Expanded(
            child: PageView.builder(
              controller: PageController(initialPage: _currentFieldIndex),
              onPageChanged: (index) {
                setState(() => _currentFieldIndex = index);
              },
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final field = fields[index];
                final controller = _fieldControllers[field];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título do campo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF1877F2).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1877F2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                field,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Campo de texto
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: controller,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                          ).merge(_getTextStyleDecoration()),
                          maxLines: field.contains('Experiência') ||
                                  field.contains('Conteúdo') ||
                                  field.contains('Cláusulas') ||
                                  field.contains('Resumo') ||
                                  field.contains('Tópicos')
                              ? 15
                              : 5,
                          decoration: InputDecoration(
                            hintText: 'Digite $field aqui...',
                            hintStyle: TextStyle(color: secondaryColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                            counterText: '',
                          ),
                          maxLength: 2000,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Contador de caracteres
                      Text(
                        '${controller?.text.length ?? 0} / 2000 caracteres',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sugestões rápidas
                      Text(
                        'Sugestões Rápidas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _getSuggestions(field).map((suggestion) {
                          return InkWell(
                            onTap: () {
                              final currentText = controller?.text ?? '';
                              controller?.text = currentText.isEmpty
                                  ? suggestion
                                  : '$currentText\n$suggestion';
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF3A3A3C)
                                    : const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF4A4A4C)
                                      : const Color(0xFFE5E5EA),
                                ),
                              ),
                              child: Text(
                                suggestion,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Indicadores de página
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                fields.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentFieldIndex
                        ? const Color(0xFF1877F2)
                        : secondaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getSuggestions(String field) {
    // Sugestões contextuais baseadas no campo
    if (field.contains('Email')) {
      return ['exemplo@email.com', 'contato@empresa.com'];
    } else if (field.contains('Telefone')) {
      return ['+244 900 000 000', '+244 910 000 000'];
    } else if (field.contains('Habilidades')) {
      return ['Trabalho em equipe', 'Comunicação', 'Liderança', 'Proativo'];
    } else if (field.contains('Formação')) {
      return ['Licenciatura em...', 'Mestrado em...', 'Curso Técnico'];
    }
    return ['Adicionar detalhes', 'Ver exemplos'];
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final bool isDark;
  final String? label;

  const _ToolbarButton({
    required this.icon,
    required this.isActive,
    required this.onPressed,
    required this.isDark,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF1877F2)
              : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Colors.white
                  : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505)),
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : (isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
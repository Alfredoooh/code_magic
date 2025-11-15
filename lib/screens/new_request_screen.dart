// lib/screens/new_request_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../widgets/custom_icons.dart';
import 'templates_gallery_screen.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final DocumentService _documentService = DocumentService();
  final TextEditingController _descriptionController = TextEditingController();
  final Map<String, TextEditingController> _fieldControllers = {};
  final ImagePicker _picker = ImagePicker();

  DocumentCategory? _selectedCategory;
  DocumentTemplate? _selectedTemplate;

  @override
  void dispose() {
    _descriptionController.dispose();
    for (var controller in _fieldControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Currículo', 'icon': CustomIcons.person, 'category': DocumentCategory.curriculum, 'color': Color(0xFF1877F2)},
    {'name': 'Certificado', 'icon': CustomIcons.certificate, 'category': DocumentCategory.certificate, 'color': Color(0xFF4CAF50)},
    {'name': 'Carta', 'icon': CustomIcons.envelope, 'category': DocumentCategory.letter, 'color': Color(0xFF9C27B0)},
    {'name': 'Relatório', 'icon': CustomIcons.description, 'category': DocumentCategory.report, 'color': Color(0xFF2196F3)},
    {'name': 'Contrato', 'icon': CustomIcons.contract, 'category': DocumentCategory.contract, 'color': Color(0xFFFF5722)},
    {'name': 'Fatura', 'icon': CustomIcons.invoice, 'category': DocumentCategory.invoice, 'color': Color(0xFF009688)},
    {'name': 'Apresentação', 'icon': CustomIcons.presentation, 'category': DocumentCategory.presentation, 'color': Color(0xFFFF9800)},
    {'name': 'Trabalho', 'icon': CustomIcons.school, 'category': DocumentCategory.essay, 'color': Color(0xFF673AB7)},
    {'name': 'Outro', 'icon': CustomIcons.folder, 'category': DocumentCategory.other, 'color': Color(0xFF607D8B)},
  ];

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

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null && mounted) {
        setState(() {
          _selectedTemplate = DocumentTemplate(
            id: 'local_${DateTime.now().millisecondsSinceEpoch}',
            name: 'Imagem da Galeria',
            description: 'Imagem selecionada do dispositivo',
            imageUrl: file.path,
            usageCount: 0,
            category: _selectedCategory ?? DocumentCategory.other,
            createdAt: DateTime.now(),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openTemplates() async {
    if (_selectedCategory == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione uma categoria primeiro'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final result = await Navigator.of(context).push<DocumentTemplate>(
      MaterialPageRoute(
        builder: (_) => TemplatesGalleryScreen(category: _selectedCategory!),
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedTemplate = result);
    }
  }

  void _send() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma categoria'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Valida campos obrigatórios
    final fields = _getCategoryFields(_selectedCategory!);
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

    try {
      final auth = context.read<AuthProvider>();

      // Cria mapa com os dados dos campos
      final fieldsData = <String, String>{};
      for (var field in fields) {
        fieldsData[field] = _fieldControllers[field]!.text.trim();
      }

      final request = DocumentRequest(
        id: '',
        userId: auth.user!.uid,
        userName: auth.user!.displayName ?? '',
        userEmail: auth.user!.email ?? '',
        templateId: _selectedTemplate?.id ?? '',
        templateName: _selectedTemplate?.name ?? '',
        category: _selectedCategory!,
        title: 'Pedido de ${_categories.firstWhere((c) => c['category'] == _selectedCategory)['name']}',
        description: _descriptionController.text.trim(),
        priority: 'normal',
        status: 'pending',
        createdAt: DateTime.now(),
        customFields: fieldsData,
      );

      await _documentService.createRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido enviado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF65676B);

    final categoryFields = _selectedCategory != null ? _getCategoryFields(_selectedCategory!) : [];

    // Garante que controllers existam para todos os campos
    for (var field in categoryFields) {
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Novo Pedido',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Categorias horizontais
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: cardColor,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['category'];
                final catColor = cat['color'] as Color;

                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = cat['category'];
                    _selectedTemplate = null;
                  }),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: isSelected ? catColor : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: catColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          cat['icon'] as String,
                          width: 28,
                          height: 28,
                          colorFilter: ColorFilter.mode(
                            isSelected ? Colors.white : textColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : textColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Área de conteúdo
          Expanded(
            child: _selectedCategory == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          CustomIcons.folder,
                          width: 64,
                          height: 64,
                          colorFilter: ColorFilter.mode(
                            secondaryColor.withOpacity(0.5),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Selecione uma categoria acima',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Template selecionado
                        if (_selectedTemplate != null) ...[
                          Text(
                            'Template Selecionado',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _selectedTemplate!.imageUrl.startsWith('http')
                                      ? Image.network(
                                          _selectedTemplate!.imageUrl,
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_selectedTemplate!.imageUrl),
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedTemplate = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.string(
                                        CustomIcons.close,
                                        width: 16,
                                        height: 16,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Campos dinâmicos baseados na categoria
                        ...categoryFields.map((field) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _fieldControllers[field],
                                    style: TextStyle(color: textColor),
                                    maxLines: field.contains('Experiência') || 
                                             field.contains('Conteúdo') || 
                                             field.contains('Cláusulas') ||
                                             field.contains('Resumo') ||
                                             field.contains('Tópicos')
                                        ? 4
                                        : 1,
                                    decoration: InputDecoration(
                                      hintText: 'Digite $field',
                                      hintStyle: TextStyle(color: secondaryColor),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        // Descrição adicional (opcional)
                        Text(
                          'Informações Adicionais (Opcional)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: 4,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Adicione qualquer informação extra aqui...',
                              hintStyle: TextStyle(color: secondaryColor),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // Barra inferior
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Botão adicionar template
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: SvgPicture.string(
                        CustomIcons.add,
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF1877F2),
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: _selectedCategory == null
                          ? null
                          : () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => Container(
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),
                                  child: SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 12),
                                        Container(
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: secondaryColor.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1877F2).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: SvgPicture.string(
                                              CustomIcons.image,
                                              width: 24,
                                              height: 24,
                                              colorFilter: const ColorFilter.mode(
                                                Color(0xFF1877F2),
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            'Galeria',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Escolher da galeria',
                                            style: TextStyle(color: secondaryColor),
                                          ),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _pickImage();
                                          },
                                        ),
                                        ListTile(
                                          leading: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1877F2).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: SvgPicture.string(
                                              CustomIcons.folder,
                                              width: 24,
                                              height: 24,
                                              colorFilter: const ColorFilter.mode(
                                                Color(0xFF1877F2),
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            'Templates',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Escolher um template',
                                            style: TextStyle(color: secondaryColor),
                                          ),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            _openTemplates();
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Botão enviar
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Enviar Pedido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.string(
                            CustomIcons.send,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// lib/screens/new_request_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../providers/theme_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../widgets/custom_icons.dart';
import 'document_request_detail_screen.dart';
import 'templates_gallery_screen.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final DocumentService _documentService = DocumentService();
  final TextEditingController _descController = TextEditingController(); // descrição do pedido (visível ao user)
  final ImagePicker _picker = ImagePicker();

  DocumentCategory? _selectedCategory;
  DocumentTemplate? _selectedTemplate; // template selecionado (app URL ou local)

  final FocusNode _descFocus = FocusNode();

  @override
  void dispose() {
    _descController.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  // ---------------- PICKERS / AÇÕES ----------------

  // Pega imagem da galeria do telefone e abre detalhe (fluxo existente)
  Future<void> _pickFromGalleryAsTemplate() async {
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      if (!mounted) return;

      final temp = DocumentTemplate(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Template (Galeria do Telefone)',
        description: 'Imagem selecionada do dispositivo',
        imageUrl: file.path, // caminho local
        usageCount: 0,
        category: _selectedCategory ?? DocumentCategory.other, // <- CORREÇÃO: categoria obrigatória
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentRequestDetailScreen(template: temp),
          fullscreenDialog: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao abrir galeria: $e')));
    }
  }

  // Abre galeria completa de templates da app e recebe template selecionado
  Future<void> _openTemplatesGallery() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione primeiro uma categoria.')));
      return;
    }

    final result = await Navigator.of(context).push<DocumentTemplate>(
      MaterialPageRoute(
        builder: (_) => TemplatesGalleryScreen(category: _selectedCategory!),
      ),
    );

    if (result != null) {
      // TEMPLATE DA APP: apenas guarda o template e mostra apenas a imagem (NÃO coloca texto no campo)
      setState(() {
        _selectedTemplate = result;
      });
      // foca no campo de descrição para o user escrever o pedido
      await Future.delayed(const Duration(milliseconds: 100));
      FocusScope.of(context).requestFocus(_descFocus);
    }
  }

  // Ao selecionar quick-template no modal ou na listagem in-place: só define _selectedTemplate (sem mostrar texto)
  void _selectAppTemplateDirect(DocumentTemplate t) {
    setState(() {
      _selectedTemplate = t;
    });
    FocusScope.of(context).requestFocus(_descFocus);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template da app seleccionado.')));
  }

  // Remove template seleccionado
  void _removeSelectedTemplate() {
    setState(() {
      _selectedTemplate = null;
    });
  }

  // ---------------- UI HELPERS ----------------

  String _getCategoryName(DocumentCategory c) {
    switch (c) {
      case DocumentCategory.curriculum:
        return 'Cria Vídeos';
      case DocumentCategory.certificate:
        return 'Certificado';
      case DocumentCategory.letter:
        return 'Abre a Câmara';
      case DocumentCategory.report:
        return 'Relatório';
      case DocumentCategory.contract:
        return 'Contrato';
      case DocumentCategory.invoice:
        return 'Fatura';
      case DocumentCategory.presentation:
        return 'Modo de Voz';
      case DocumentCategory.essay:
        return 'Trabalho';
      case DocumentCategory.other:
        return 'Outro';
    }
  }

  String _getCategoryIcon(DocumentCategory c) {
    switch (c) {
      case DocumentCategory.curriculum:
        return CustomIcons.person;
      case DocumentCategory.certificate:
        return CustomIcons.certificate;
      case DocumentCategory.letter:
        return CustomIcons.camera;
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

  Color _categoryColor(DocumentCategory c) {
    switch (c) {
      case DocumentCategory.curriculum:
        return const Color(0xFF1877F2);
      case DocumentCategory.certificate:
        return const Color(0xFF4CAF50);
      case DocumentCategory.letter:
        return const Color(0xFF9C27B0);
      case DocumentCategory.report:
        return const Color(0xFF2196F3);
      case DocumentCategory.contract:
        return const Color(0xFFFF5722);
      case DocumentCategory.invoice:
        return const Color(0xFF009688);
      case DocumentCategory.presentation:
        return const Color(0xFFFF9800);
      case DocumentCategory.essay:
        return const Color(0xFF673AB7);
      case DocumentCategory.other:
        return const Color(0xFF607D8B);
    }
  }

  // Preview da imagem do template (se houver) — só mostra a imagem (sem texto)
  Widget _buildTemplatePreview(double size) {
    if (_selectedTemplate == null) {
      return SizedBox(width: size, height: size);
    }
    final url = _selectedTemplate!.imageUrl;
    final isHttp = url.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        color: Colors.black12,
        child: isHttp
            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
            : Image.file(File(url), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
      ),
    );
  }

  // ---------------- MODAL DO BOTÃO + ----------------

  void _openAddMenu() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escolha uma categoria primeiro.')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [const Text('Adicionar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(), TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))]),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _pickFromGalleryAsTemplate(); // galeria do telefone -> detalhe
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.photo_library, size: 28), SizedBox(height: 6), Text('Template da Galeria\n(Teléfone)', textAlign: TextAlign.center)]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAppTemplatesModal();
                        },
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: Column(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.cloud_download, size: 28), SizedBox(height: 6), Text('Template da App\n(URLs)', textAlign: TextAlign.center)]),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Escolher ficheiro local'),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _pickFromGalleryAsTemplate();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modal com quick templates da app; ao tocar em um template, fecha e chama _selectAppTemplateDirect
  void _showAppTemplatesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [const Text('Templates da App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const Spacer(), TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fechar'))]),
                const SizedBox(height: 8),
                StreamBuilder<List<DocumentTemplate>>(
                  stream: _document_service_getTemplatesStreamGuard(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
                    }
                    final templates = snap.data ?? [];
                    final quick = templates.take(2).toList();
                    if (quick.isEmpty) {
                      return Column(mainAxisSize: MainAxisSize.min, children: [
                        const SizedBox(height: 12),
                        const Text('Nenhum template rápido nesta categoria.'),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(ctx); _openTemplatesGallery(); }, child: const Text('Abrir galeria completa de templates'))),
                      ]);
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 140,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (_, i) {
                              final t = quick[i];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _selectAppTemplateDirect(t); // <-- apenas define _selectedTemplate e foca descrição
                                },
                                child: Container(
                                  width: 160,
                                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)]),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                    Expanded(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), child: Image.network(t.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)))),
                                    Padding(padding: const EdgeInsets.all(8.0), child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  ]),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemCount: quick.length,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(ctx); _openTemplatesGallery(); }, child: const Text('Ver todos os templates desta categoria'))),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Pequeno wrapper para evitar repetição de getTemplatesByCategory chamadas nulas
  Stream<List<DocumentTemplate>> _document_service_getTemplatesStreamGuard() {
    if (_selectedCategory == null) {
      // stream vazio quando não há categoria selecionada
      return const Stream<List<DocumentTemplate>>.empty();
    }
    return _documentService.getTemplatesByCategory(_selectedCategory!);
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF0B0B0B) : const Color(0xFFF8F9FB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Nova Requisição'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Horizontal categories (cards grandes)
            SizedBox(
              height: 110,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: DocumentCategory.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final cat = DocumentCategory.values[index];
                  final selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = selected ? null : cat),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected ? (isDark ? Colors.white12 : Colors.blue.shade50) : (isDark ? const Color(0xFF141414) : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: selected ? _categoryColor(cat) : Colors.transparent, width: selected ? 1.6 : 0),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: _categoryColor(cat).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: SvgPicture.string(_getCategoryIcon(cat), width: 22, height: 22, colorFilter: ColorFilter.mode(_categoryColor(cat), BlendMode.srcIn))),
                        ),
                        const Spacer(),
                        Text(_getCategoryName(cat), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
                      ]),
                    ),
                  );
                },
              ),
            ),

            // --- IN-PLACE TEMPLATES: aparece quando uma categoria está seleccionada ---
            if (_selectedCategory != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Text('Templates desta categoria', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: _openTemplatesGallery,
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 140,
                child: StreamBuilder<List<DocumentTemplate>>(
                  stream: _document_service_getTemplatesStreamGuard(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Erro ao carregar templates: ${snap.error}'));
                    }
                    final templates = snap.data ?? [];
                    if (templates.isEmpty) {
                      return const Center(child: Text('Nenhum template nesta categoria'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: templates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final t = templates[i];
                        final selected = _selectedTemplate != null && _selectedTemplate!.id == t.id;
                        return GestureDetector(
                          onTap: () => _selectAppTemplateDirect(t),
                          child: Container(
                            width: 160,
                            decoration: BoxDecoration(
                              color: selected ? (isDark ? Colors.white12 : Colors.blue.shade50) : (isDark ? const Color(0xFF141414) : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? _categoryColor(_selectedCategory!) : Colors.transparent, width: selected ? 1.6 : 0),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.network(t.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],

            const Spacer(),

            // Área inferior: preview (imagem do template selecionado) + campo descrição visível ao user + botão +
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF0F0F0F) : Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Linha superior: preview da imagem (só imagem) + espaço para remover template selecionado
                    Row(
                      children: [
                        _buildTemplatePreview(64), // preview só imagem; se null mostra espaço vazio
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Descrição do pedido', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text('Escreve aqui o que queres que a app faça (visível ao utilizador).', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54)),
                            ],
                          ),
                        ),
                        if (_selectedTemplate != null)
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _removeSelectedTemplate,
                            tooltip: 'Remover template selecionado',
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Campo de descrição (visível ao usuário) - é aqui que o usuário descreve o pedido
                    TextField(
                      controller: _descController,
                      focusNode: _descFocus,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        hintText: 'Descreva o pedido (ex: "Criar um folheto A4 com título X, cores Y...")',
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Botões: + abre modal de adicionar template / enviar (exemplo)
                    Row(
                      children: [
                        InkWell(
                          onTap: _openAddMenu,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.white10 : Colors.grey.shade100),
                            child: const Icon(Icons.add, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Aqui tu processas o envio; envio com dados:
                              // _selectedCategory, _selectedTemplate (opcional, invisível), _descController.text (visível)
                              final desc = _descController.text.trim();
                              if (_selectedCategory == null) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escolha uma categoria antes de enviar.')));
                                return;
                              }
                              if (desc.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Descreve o pedido antes de enviar.')));
                                return;
                              }

                              // Exemplo simples: mostra resumo (sem expor dados do template ao user aqui)
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido preparado. (Implementa envio real)')));

                              // Implementa envio real: envia _selectedCategory, _selectedTemplate (se != null) e desc.
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text('Enviar Pedido'),
                            ),
                          ),
                        ),
                      ],
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
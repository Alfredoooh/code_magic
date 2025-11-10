// lib/screens/new_request_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../services/document_service.dart';
import '../models/document_template_model.dart';
import '../models/advertisement_model.dart';
import '../widgets/custom_icons.dart';
import 'document_request_detail_screen.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final DocumentService _documentService = DocumentService();
  final PageController _adPageController = PageController(viewportFraction: 0.92);
  Timer? _adTimer;
  int _currentAdPage = 0;

  DocumentCategory? _selectedCategory;
  DocumentTemplate? _selectedTemplate;
  bool _showingTemplates = false;

  final List<Advertisement> _advertisements = [
    Advertisement(
      id: 'ad_001',
      title: 'Template Premium de Currículo',
      description: 'Destaque-se no mercado com nossos templates profissionais',
      imageUrl: 'https://via.placeholder.com/400x200/1877F2/FFFFFF?text=Curriculo+Premium',
      actionUrl: 'https://example.com/premium/curriculum',
      actionText: 'Ver Mais',
      category: 'curriculum',
      backgroundColor: '#1877F2',
      priority: 1,
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 365)),
    ),
    Advertisement(
      id: 'ad_002',
      title: 'Certificados Personalizados',
      description: 'Crie certificados impressionantes em minutos',
      imageUrl: 'https://via.placeholder.com/400x200/4CAF50/FFFFFF?text=Certificados',
      actionUrl: 'https://example.com/templates/certificates',
      actionText: 'Explorar',
      category: 'certificate',
      backgroundColor: '#4CAF50',
      priority: 2,
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 365)),
    ),
    Advertisement(
      id: 'ad_003',
      title: 'Apresentações Profissionais',
      description: 'Slides modernos para suas apresentações de negócios',
      imageUrl: 'https://via.placeholder.com/400x200/FF9800/FFFFFF?text=Apresentacoes',
      actionUrl: 'https://example.com/premium/presentations',
      actionText: 'Começar Agora',
      category: 'presentation',
      backgroundColor: '#FF9800',
      priority: 3,
      isActive: true,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 365)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAdAutoRotation();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _adPageController.dispose();
    super.dispose();
  }

  void _startAdAutoRotation() {
    _adTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_adPageController.hasClients) {
        final nextPage = (_currentAdPage + 1) % _advertisements.length;
        _adPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _getCategoryName(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.curriculum:
        return 'Currículo';
      case DocumentCategory.certificate:
        return 'Certificado';
      case DocumentCategory.letter:
        return 'Carta';
      case DocumentCategory.report:
        return 'Relatório';
      case DocumentCategory.contract:
        return 'Contrato';
      case DocumentCategory.invoice:
        return 'Fatura';
      case DocumentCategory.presentation:
        return 'Apresentação';
      case DocumentCategory.essay:
        return 'Trabalho Acadêmico';
      case DocumentCategory.other:
        return 'Outro';
    }
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

  String _getCategoryDescription(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.curriculum:
        return 'CV profissional e portfólio';
      case DocumentCategory.certificate:
        return 'Certificados e diplomas';
      case DocumentCategory.letter:
        return 'Cartas formais e informais';
      case DocumentCategory.report:
        return 'Relatórios técnicos e executivos';
      case DocumentCategory.contract:
        return 'Contratos e acordos';
      case DocumentCategory.invoice:
        return 'Faturas e recibos';
      case DocumentCategory.presentation:
        return 'Slides e apresentações';
      case DocumentCategory.essay:
        return 'TCC, artigos e trabalhos';
      case DocumentCategory.other:
        return 'Outros documentos';
    }
  }

  Color _getCategoryColor(DocumentCategory category) {
    switch (category) {
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

  void _selectCategory(DocumentCategory category, bool isDark) {
    setState(() {
      _selectedCategory = category;
      _selectedTemplate = null;
      _showingTemplates = true;
    });
  }

  void _selectTemplate(DocumentTemplate template) {
    setState(() {
      _selectedTemplate = template;
    });

    // Navega em fullscreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentRequestDetailScreen(template: template),
        fullscreenDialog: true,
      ),
    );
  }

  void _backToCategories() {
    setState(() {
      _showingTemplates = false;
      _selectedCategory = null;
      _selectedTemplate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);

    if (_showingTemplates && _selectedCategory != null) {
      return _buildTemplatesView(isDark, bgColor);
    }

    return _buildCategoriesView(isDark, bgColor);
  }

  Widget _buildCategoriesView(bool isDark, Color bgColor) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Container(
      color: bgColor,
      child: CustomScrollView(
        slivers: [
          // Carrossel de Anúncios
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 180,
                    child: PageView.builder(
                      controller: _adPageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentAdPage = index;
                        });
                      },
                      itemCount: _advertisements.length,
                      itemBuilder: (context, index) {
                        return _AdCard(
                          ad: _advertisements[index],
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _advertisements.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentAdPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentAdPage == index
                              ? const Color(0xFF1877F2)
                              : (isDark
                                  ? const Color(0xFF3A3B3C)
                                  : const Color(0xFFDADADA)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Título
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Categorias de Documentos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Grid de Categorias
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = DocumentCategory.values[index];
                  return _CategoryCard(
                    category: category,
                    name: _getCategoryName(category),
                    description: _getCategoryDescription(category),
                    icon: _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                    onTap: () => _selectCategory(category, isDark),
                    isDark: isDark,
                    cardColor: cardColor,
                    textColor: textColor,
                  );
                },
                childCount: DocumentCategory.values.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildTemplatesView(bool isDark, Color bgColor) {
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: SvgPicture.string(
                    CustomIcons.arrowLeft,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                  ),
                  onPressed: _backToCategories,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getCategoryName(_selectedCategory!),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        'Escolha um template',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<DocumentTemplate>>(
              stream: _documentService.getTemplatesByCategory(_selectedCategory!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                final templates = snapshot.data ?? [];

                if (templates.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.string(
                          CustomIcons.folder,
                          width: 64,
                          height: 64,
                          colorFilter: ColorFilter.mode(
                            isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum template disponível',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    return _TemplateCard(
                      template: templates[index],
                      onTap: () => _selectTemplate(templates[index]),
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final Advertisement ad;
  final bool isDark;

  const _AdCard({
    required this.ad,
    required this.isDark,
  });

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              ad.imageUrl,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ad.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ad.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _CategoryCard extends StatelessWidget {
  final DocumentCategory category;
  final String name;
  final String description;
  final String icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color textColor;

  const _CategoryCard({
    required this.category,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SvgPicture.string(
                    icon,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class _TemplateCard extends StatelessWidget {
  final DocumentTemplate template;
  final VoidCallback onTap;
  final bool isDark;
  final Color cardColor;
  final Color textColor;

  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  template.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (template.usageCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SvgPicture.string(
                          CustomIcons.star,
                          width: 12,
                          height: 12,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFFFA000),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${template.usageCount} usos',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
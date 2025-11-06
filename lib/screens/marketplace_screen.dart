// lib/screens/marketplace_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_icons.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String selectedCategory = 'Todos';

  // somente categorias para produtos eletrónicos/digitais
  final List<String> categories = [
    'Todos',
    'Eletrônicos',
    'Livros',
    'Software',
    'Música',
    'Cursos',
    'Templates',
  ];

  static const Color _activeBlue = Color(0xFF1877F2);

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = context.watch<AuthProvider>();

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final iconColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final dividerColor = isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // AppBar no mesmo formato do users_screen.dart (fixo)
          SliverAppBar(
            pinned: true,
            backgroundColor: cardColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                SvgIcon(svgString: CustomIcons.marketplace, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Marketplace',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                height: 0.5,
              ),
            ),
            actions: [
              // botão adicionar textual aqui também (mantém consistência)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton(
                  onPressed: () => _showCreateProductModal(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _activeBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),

          // Categorias como toggles (Filled / Filled.tonal)
          SliverToBoxAdapter(
            child: Container(
              color: bgColor,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: categories.map((category) {
                    final bool isSelected = selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: isSelected
                          ? _buildActiveCategoryButton(category, isDark)
                          : _buildTonalCategoryButton(category, isDark),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Lista de produtos (grid)
          StreamBuilder<QuerySnapshot>(
            stream: selectedCategory == 'Todos'
                ? FirebaseFirestore.instance
                    .collection('marketplace_products')
                    .orderBy('createdAt', descending: true)
                    .snapshots()
                : FirebaseFirestore.instance
                    .collection('marketplace_products')
                    .where('category', isEqualTo: selectedCategory)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // usa o ícone de erro do custom icons
                        SvgIcon(
                          svgString: CustomIcons.errorIcon,
                          size: 72,
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar produtos',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_activeBlue),
                    ),
                  ),
                );
              }

              final products = snapshot.data?.docs ?? [];

              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgIcon(
                          svgString: CustomIcons.document,
                          size: 80,
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum item encontrado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seja o primeiro a anunciar um conteúdo digital!',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final productDoc = products[index];
                      final data = productDoc.data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () => _showProductDetails(context, data),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Imagem/cover do item digital (ex: capa de livro)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: data['imageURL'] != null
                                      ? Image.network(
                                          data['imageURL'],
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                                          child: Icon(
                                            Icons.image,
                                            size: 48,
                                            color: isDark ? const Color(0xFF65676B) : const Color(0xFFB0B3B8),
                                          ),
                                        ),
                                ),
                              ),
                              // Informações do produto
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['title'] ?? 'Sem título',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${data['price'] ?? '0'},00 Kz',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _activeBlue,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        data['category'] ?? 'Categoria',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // botão tonal (não activo)
  Widget _buildTonalCategoryButton(String category, bool isDark) {
    final bg = isDark ? const Color(0xFF2D3236) : const Color(0xFFF0F2F5);
    final labelColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return FilledButton.tonal(
      onPressed: () {
        setState(() => selectedCategory = category);
      },
      style: FilledButton.styleFrom(
        // tonal: usamos uma cor neutra próxima ao card para "tonal" visual consistente
        backgroundColor: bg,
        foregroundColor: labelColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        category,
        style: TextStyle(fontWeight: FontWeight.w600, color: labelColor),
      ),
    );
  }

  // botão activo (filled) com check no final (CustomIcons.ok)
  Widget _buildActiveCategoryButton(String category, bool isDark) {
    return FilledButton(
      onPressed: () {
        // mantém selecionado ao clicar de novo
      },
      style: FilledButton.styleFrom(
        backgroundColor: _activeBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          // usamos o ícone "ok" do custom_icons (orientação correta definida no SVG)
          SvgIcon(svgString: CustomIcons.ok, size: 16, color: Colors.white),
        ],
      ),
    );
  }

  void _showCreateProductModal(BuildContext context) {
    // TODO: Implementar modal de criação de produto (criação de conteúdo digital)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade em desenvolvimento'),
        backgroundColor: _activeBlue,
      ),
    );
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> product) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detalhes do Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product['imageURL'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product['imageURL'],
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      product['title'] ?? 'Sem título',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${product['price'] ?? '0'},00 Kz',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _activeBlue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Descrição',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product['description'] ?? 'Sem descrição',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implementar download/compra/contato para conteúdo digital
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Contactar Vendedor',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
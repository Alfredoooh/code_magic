// lib/screens/marketplace_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
import 'marketplace/book_details_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String selectedCategory = 'Todos';

  final List<Map<String, dynamic>> categories = [
    {'name': 'Todos', 'icon': CustomIcons.globe},
    {'name': 'Investimentos', 'icon': CustomIcons.trendingUp},
    {'name': 'Trading', 'icon': CustomIcons.chartBar},
    {'name': 'Finanças Pessoais', 'icon': CustomIcons.wallet},
    {'name': 'Economia', 'icon': CustomIcons.currencyDollar},
    {'name': 'Criptomoedas', 'icon': CustomIcons.bitcoin},
    {'name': 'Análise Técnica', 'icon': CustomIcons.chartLine},
    {'name': 'Mercado de Ações', 'icon': CustomIcons.buildingLibrary},
    {'name': 'Empreendedorismo', 'icon': CustomIcons.lightBulb},
    {'name': 'Biografias', 'icon': CustomIcons.userCircle},
    {'name': 'Estratégias', 'icon': CustomIcons.puzzle},
    {'name': 'Educação Financeira', 'icon': CustomIcons.academicCap},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    // --- CORREÇÃO: usar a coleção "marketplace_products" (conforme suas regras)
    final CollectionReference productsColl = FirebaseFirestore.instance.collection('marketplace_products');

    final Stream<QuerySnapshot> booksStream = selectedCategory == 'Todos'
        ? productsColl.orderBy('createdAt', descending: true).snapshots()
        : productsColl
            .where('category', isEqualTo: selectedCategory)
            .orderBy('createdAt', descending: true)
            .snapshots();

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Categorias (sem AppBar)
          SliverToBoxAdapter(
            child: Container(
              color: bgColor,
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: categories.map((category) {
                    final bool isSelected = selectedCategory == category['name'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCategoryChip(
                        category['name'],
                        category['icon'],
                        isSelected,
                        isDark,
                        textColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // Lista de livros (grid)
          StreamBuilder<QuerySnapshot>(
            stream: booksStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                // exibe a mensagem de erro do snapshot para debug
                return SliverFillRemaining(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erro ao carregar livros',
                            style: TextStyle(
                              fontSize: 16,
                              color: hintColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: hintColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                    ),
                  ),
                );
              }

              final books = snapshot.data?.docs ?? [];

              if (books.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 80,
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum livro encontrado',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Seja o primeiro a adicionar um livro!',
                          style: TextStyle(
                            fontSize: 14,
                            color: hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bookDoc = books[index];
                      final data = bookDoc.data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookDetailsScreen(
                                bookId: bookDoc.id,
                                bookData: data,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Capa do livro
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: AspectRatio(
                                  aspectRatio: 0.7,
                                  child: data['coverImageURL'] != null
                                      ? Image.network(
                                          data['coverImageURL'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, st) => Container(
                                            color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                                            child: Icon(Icons.broken_image, color: hintColor),
                                          ),
                                        )
                                      : Container(
                                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                                          child: Icon(
                                            Icons.menu_book,
                                            size: 48,
                                            color: hintColor,
                                          ),
                                        ),
                                ),
                              ),
                              // Informações do livro
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['title'] ?? 'Sem título',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['author'] ?? 'Autor desconhecido',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: hintColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      if (data['digitalPrice'] != null)
                                        Text(
                                          '${data['digitalPrice']} Kz',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1877F2),
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
                    },
                    childCount: books.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    String name,
    String iconSvg,
    bool isSelected,
    bool isDark,
    Color textColor,
  ) {
    const blueColor = Color(0xFF1877F2);

    return GestureDetector(
      onTap: () {
        setState(() => selectedCategory = name);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? blueColor : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgIcon(
              svgString: iconSvg,
              color: isSelected ? Colors.white : blueColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
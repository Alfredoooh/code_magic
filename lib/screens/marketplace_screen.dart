// lib/screens/marketplace_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  List<Map<String, dynamic>> allBooks = [];
  bool isLoading = true;
  String? error;
  int currentFileIndex = 1;
  bool hasMoreBooks = true;

  // URL da sua API
  static const String _apiBaseUrl = 'https://data-9v20.onrender.com';

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
  void initState() {
    super.initState();
    _fetchAllBooks();
  }

  Future<void> _fetchAllBooks() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📚 BUSCANDO LIVROS DA API...');
    print('♾️ Modo infinito ativado');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final List<Map<String, dynamic>> loadedBooks = [];
    int consecutiveErrors = 0;
    int filesLoaded = 0;
    int currentFile = 1;

    // Busca livros até encontrar 3 erros consecutivos
    while (consecutiveErrors < 3 && filesLoaded < 20) {
      final url = '$_apiBaseUrl/books/book$currentFile.json';
      print('🔍 Tentando: book$currentFile.json');

      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List? books = data['books'];

          if (books != null && books.isNotEmpty) {
            print('   ✅ ${books.length} livros encontrados');
            loadedBooks.addAll(List<Map<String, dynamic>>.from(books));
            filesLoaded++;
            consecutiveErrors = 0;
          } else {
            print('   ⚠️ Arquivo vazio');
            consecutiveErrors++;
          }
        } else if (response.statusCode == 404) {
          print('   ⚠️ Arquivo não existe (404)');
          consecutiveErrors++;
        } else {
          print('   ⚠️ Erro ${response.statusCode}');
          consecutiveErrors++;
        }
      } catch (e) {
        print('   ❌ Erro: $e');
        consecutiveErrors++;
      }

      currentFile++;
    }

    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    if (loadedBooks.isEmpty) {
      print('❌ NENHUM LIVRO CARREGADO!');
      setState(() {
        error = 'Nenhum livro disponível no momento';
        isLoading = false;
      });
    } else {
      print('✅ ${loadedBooks.length} LIVROS CARREGADOS!');
      print('📂 $filesLoaded arquivos processados');
      setState(() {
        allBooks = loadedBooks;
        isLoading = false;
        hasMoreBooks = consecutiveErrors < 3;
      });
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('');
  }

  List<Map<String, dynamic>> get filteredBooks {
    if (selectedCategory == 'Todos') return allBooks;
    return allBooks.where((book) => book['category'] == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Categorias
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

          // Conteúdo
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Carregando livros...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar livros',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: hintColor),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _fetchAllBooks,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar Novamente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1877F2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredBooks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_outlined, size: 80, color: hintColor),
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
                      'Tente outra categoria',
                      style: TextStyle(fontSize: 14, color: hintColor),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
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
                    final book = filteredBooks[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookDetailsScreen(
                              bookId: book['id'] ?? '',
                              bookData: book,
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
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: AspectRatio(
                                aspectRatio: 0.7,
                                child: book['coverImageURL'] != null
                                    ? Image.network(
                                        book['coverImageURL'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (ctx, err, st) => Container(
                                          color: isDark
                                              ? const Color(0xFF3A3B3C)
                                              : const Color(0xFFF0F2F5),
                                          child: Icon(Icons.broken_image, color: hintColor),
                                        ),
                                      )
                                    : Container(
                                        color: isDark
                                            ? const Color(0xFF3A3B3C)
                                            : const Color(0xFFF0F2F5),
                                        child: Icon(Icons.menu_book, size: 48, color: hintColor),
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
                                      book['title'] ?? 'Sem título',
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
                                      book['author'] ?? 'Autor desconhecido',
                                      style: TextStyle(fontSize: 12, color: hintColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    if (book['digitalPrice'] != null)
                                      Text(
                                        '${book['digitalPrice']} Kz',
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
                  childCount: filteredBooks.length,
                ),
              ),
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
          color: isSelected
              ? blueColor
              : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5)),
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
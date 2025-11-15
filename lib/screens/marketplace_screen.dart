import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_icons.dart';
import 'marketplace/book_details_screen.dart';
import 'marketplace/all_books_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with AutomaticKeepAliveClientMixin {
  String selectedCategory = 'Todos';
  List<Map<String, dynamic>> allBooks = [];
  bool isLoading = true;
  String? error;
  int _currentFile = 1;
  bool _hasMoreBooks = true;
  final ScrollController _scrollController = ScrollController();

  // Seed para randomização baseado no usuário
  int _userSeed = 0;

  static const String _apiBaseUrl = 'https://raw.githubusercontent.com/Alfredoooh/data-server/main/public';

  final Map<String, String> _categoryIcons = {
    'Investimentos': CustomIcons.trendingUp,
    'Trading': CustomIcons.chartBar,
    'Finanças Pessoais': CustomIcons.wallet,
    'Economia': CustomIcons.currencyDollar,
    'Criptomoedas': CustomIcons.bitcoin,
    'Análise Técnica': CustomIcons.chartLine,
    'Mercado de Ações': CustomIcons.buildingLibrary,
    'Empreendedorismo': CustomIcons.lightBulb,
    'Biografias': CustomIcons.userCircle,
    'Estratégias': CustomIcons.puzzle,
    'Educação Financeira': CustomIcons.academicCap,
    'Produtividade': CustomIcons.chartBar,
    'Desenvolvimento Pessoal': CustomIcons.userCircle,
    'Psicologia': CustomIcons.lightBulb,
    'História': CustomIcons.buildingLibrary,
    'Liderança': CustomIcons.userCircle,
    'Educação': CustomIcons.academicCap,
    'Tecnologia': CustomIcons.chartLine,
    'Bem-estar': CustomIcons.lightBulb,
    'Arte': CustomIcons.lightBulb,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeSeed();
    _fetchAllBooks();
  }

  void _initializeSeed() {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid ?? '';
    // Seed único por usuário + dia do ano (muda diariamente)
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    _userSeed = userId.hashCode + dayOfYear;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get dynamicCategories {
    final Map<String, int> categoryCount = {};

    for (var book in allBooks) {
      final category = book['category'] as String? ?? 'Outros';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    List<Map<String, dynamic>> categories = [
      {'name': 'Todos', 'icon': CustomIcons.globe, 'count': allBooks.length}
    ];

    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedCategories) {
      categories.add({
        'name': entry.key,
        'icon': _categoryIcons[entry.key] ?? CustomIcons.puzzle,
        'count': entry.value,
      });
    }

    return categories;
  }

  Future<void> _fetchAllBooks() async {
    setState(() {
      isLoading = true;
      error = null;
      _currentFile = 1;
      _hasMoreBooks = true;
      allBooks.clear();
      selectedCategory = 'Todos';
    });

    await _fetchBooksFromAPI();

    setState(() => isLoading = false);
  }

  Future<void> _fetchBooksFromAPI() async {
    int consecutiveErrors = 0;
    const maxConsecutiveErrors = 3;
    int filesLoaded = 0;
    final List<Map<String, dynamic>> loadedBooks = [];

    try {
      while (consecutiveErrors < maxConsecutiveErrors && filesLoaded < 5 && _hasMoreBooks) {
        final url = '$_apiBaseUrl/books/book$_currentFile.json';

        try {
          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            try {
              final data = jsonDecode(response.body);
              List? books;

              if (data['books'] != null) {
                books = data['books'] as List?;
              } else if (data is List) {
                books = data;
              }

              if (books != null && books.isNotEmpty) {
                filesLoaded++;
                consecutiveErrors = 0;

                for (var i = 0; i < books.length; i++) {
                  final book = books[i];
                  try {
                    final normalizedBook = {
                      'id': book['id'] ?? 'book_${_currentFile}_$i',
                      'title': book['title'] ?? 'Sem título',
                      'author': book['author'] ?? 'Autor desconhecido',
                      'category': book['category'] ?? 'Outros',
                      'coverImageURL': book['coverImageURL'],
                      'description': book['description'] ?? '',
                      'preview': book['preview'],
                      'readLink': book['readLink'],
                      'digitalPrice': book['digitalPrice'],
                      'physicalPrice': book['physicalPrice'],
                      'rating': book['rating'],
                      'pages': book['pages'],
                      'publisher': book['publisher'],
                      'publishedDate': book['publishedDate'],
                      'language': book['language'] ?? 'pt',
                      'isbn': book['isbn'],
                      'format': book['format'] ?? ['Digital'],
                      'inStock': book['inStock'] ?? true,
                      'hasPhysicalVersion': book['physicalPrice'] != null,
                    };

                    if (normalizedBook['title'] != 'Sem título') {
                      loadedBooks.add(normalizedBook);
                    }
                  } catch (e) {
                    // Skip
                  }
                }
                _currentFile++;
              } else {
                consecutiveErrors++;
                _currentFile++;
              }
            } catch (e) {
              consecutiveErrors++;
              _currentFile++;
            }
          } else if (response.statusCode == 404) {
            consecutiveErrors++;
          } else {
            consecutiveErrors++;
            _currentFile++;
          }
        } catch (e) {
          consecutiveErrors++;
          if (consecutiveErrors < maxConsecutiveErrors) {
            _currentFile++;
          }
        }

        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (consecutiveErrors >= maxConsecutiveErrors) {
        _hasMoreBooks = false;
      }

      if (loadedBooks.isNotEmpty && mounted) {
        setState(() {
          allBooks.addAll(loadedBooks);
        });
      } else if (allBooks.isEmpty && mounted) {
        setState(() {
          error = 'Nenhum livro disponível no momento.';
        });
      }
    } catch (e) {
      if (mounted && allBooks.isEmpty) {
        setState(() {
          error = 'Erro ao carregar livros: $e';
        });
      }
    }
  }

  List<Map<String, dynamic>> get filteredBooks {
    if (selectedCategory == 'Todos') return allBooks;
    return allBooks.where((book) => book['category'] == selectedCategory).toList();
  }

  // Randomiza livros baseado no seed do usuário
  List<Map<String, dynamic>> _shuffleBooks(List<Map<String, dynamic>> books, int seed) {
    final random = Random(seed);
    final shuffled = List<Map<String, dynamic>>.from(books);
    for (int i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  // Organiza livros em seções
  Map<String, List<Map<String, dynamic>>> _organizeBooks() {
    final books = filteredBooks;
    final organized = <String, List<Map<String, dynamic>>>{};

    if (selectedCategory == 'Todos') {
      // Seção "Em Destaque" - livros com rating alto
      final featured = books.where((b) => b['rating'] != null && b['rating'] >= 4.0).toList();
      if (featured.isNotEmpty) {
        organized['⭐ Em Destaque'] = _shuffleBooks(featured, _userSeed).take(10).toList();
      }

      // Seção "Lançamentos" - livros mais recentes
      final recent = books.where((b) => b['publishedDate'] != null).toList()
        ..sort((a, b) {
          final dateA = a['publishedDate'] ?? '';
          final dateB = b['publishedDate'] ?? '';
          return dateB.compareTo(dateA);
        });
      if (recent.isNotEmpty) {
        organized['🆕 Lançamentos'] = recent.take(10).toList();
      }

      // Seção "Mais Populares" - shuffled para variar
      final popular = _shuffleBooks(books, _userSeed + 100).take(10).toList();
      if (popular.isNotEmpty) {
        organized['🔥 Mais Populares'] = popular;
      }

      // Seções por categoria (as top 3 categorias)
      final categoryMap = <String, List<Map<String, dynamic>>>{};
      for (var book in books) {
        final cat = book['category'] ?? 'Outros';
        categoryMap.putIfAbsent(cat, () => []);
        categoryMap[cat]!.add(book);
      }

      final sortedCategories = categoryMap.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));

      for (var i = 0; i < sortedCategories.length && i < 5; i++) {
        final entry = sortedCategories[i];
        if (entry.value.length >= 3) {
          organized['📚 ${entry.key}'] = _shuffleBooks(entry.value, _userSeed + i).take(10).toList();
        }
      }
    } else {
      // Categoria específica
      organized['📚 $selectedCategory'] = _shuffleBooks(books, _userSeed).toList();
    }

    return organized;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Filtros de categoria
          if (!isLoading && allBooks.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: bgColor,
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: dynamicCategories.map((category) {
                      final bool isSelected = selectedCategory == category['name'];
                      final int count = category['count'] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryChip(
                          category['name'],
                          category['icon'],
                          count,
                          isSelected,
                          isDark,
                          textColor,
                          hintColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // Loading
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
                    Text('Carregando livros...', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            )
          // Erro
          else if (error != null && allBooks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: hintColor),
                      const SizedBox(height: 16),
                      Text('Erro ao carregar', style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Text(error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: hintColor)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchAllBooks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          // Vazio
          else if (filteredBooks.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.menu_book_outlined, size: 80, color: hintColor),
                    const SizedBox(height: 16),
                    Text('Nenhum livro nesta categoria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    Text('Tente selecionar outra categoria', style: TextStyle(fontSize: 14, color: hintColor)),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => setState(() => selectedCategory = 'Todos'),
                      child: const Text('Ver todos os livros'),
                    ),
                  ],
                ),
              ),
            )
          // Conteúdo organizado
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, sectionIndex) {
                  final organized = _organizeBooks();
                  final sections = organized.entries.toList();
                  
                  if (sectionIndex >= sections.length) return null;

                  final section = sections[sectionIndex];
                  final sectionTitle = section.key;
                  final sectionBooks = section.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                sectionTitle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (sectionBooks.length > 5)
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AllBooksScreen(
                                        title: sectionTitle,
                                        books: sectionBooks,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Ver mais',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1877F2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: sectionBooks.length > 10 ? 10 : sectionBooks.length,
                          itemBuilder: (context, index) {
                            final book = sectionBooks[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildBookCard(book, isDark, cardColor, textColor, hintColor),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
                childCount: _organizeBooks().length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookCard(
    Map<String, dynamic> book,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color hintColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailsScreen(
              bookId: book['id'] ?? '',
              bookData: book,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: book['coverImageURL'] != null
                    ? Image.network(
                        book['coverImageURL'],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                        errorBuilder: (ctx, err, st) {
                          return Container(
                            color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                            child: Icon(Icons.broken_image, color: hintColor, size: 48),
                          );
                        },
                      )
                    : Container(
                        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                        child: Icon(Icons.menu_book, size: 48, color: hintColor),
                      ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book['title'] ?? 'Sem título',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book['author'] ?? 'Autor desconhecido',
                          style: TextStyle(fontSize: 11, color: hintColor, height: 1.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (book['digitalPrice'] != null)
                          Text(
                            '${book['digitalPrice']} Kz',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1877F2)),
                          )
                        else
                          Text('Consultar', style: TextStyle(fontSize: 11, color: hintColor, fontWeight: FontWeight.w600)),
                        if (book['rating'] != null)
                          Row(
                            children: [
                              const Icon(Icons.star, size: 12, color: Color(0xFFFFB800)),
                              const SizedBox(width: 2),
                              Text(book['rating'].toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
                            ],
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

  Widget _buildCategoryChip(String name, String iconSvg, int count, bool isSelected, bool isDark, Color textColor, Color hintColor) {
    const blueColor = Color(0xFF1877F2);
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = name),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? blueColor : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgIcon(svgString: iconSvg, color: isSelected ? Colors.white : blueColor, size: 16),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : textColor)),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : blueColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(count.toString(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : blueColor)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
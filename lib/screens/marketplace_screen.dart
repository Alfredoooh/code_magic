import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  bool isLoadingMore = false;
  String? error;
  int _currentFile = 1;
  bool _hasMoreBooks = true;
  final ScrollController _scrollController = ScrollController();

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
  };

  List<Map<String, dynamic>> get dynamicCategories {
    final Map<String, int> categoryCount = {};

    for (var book in allBooks) {
      final category = book['category'] as String? ?? 'Outros';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    List<Map<String, dynamic>> categories = [
      {
        'name': 'Todos',
        'icon': CustomIcons.globe,
        'count': allBooks.length
      }
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

  @override
  void initState() {
    super.initState();
    _fetchAllBooks();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      if (!isLoadingMore && _hasMoreBooks) {
        _loadMoreBooks();
      }
    }
  }

  Future<void> _loadMoreBooks() async {
    if (isLoadingMore || !_hasMoreBooks) return;

    setState(() => isLoadingMore = true);

    await _fetchBooksFromAPI();

    setState(() => isLoadingMore = false);
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
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            try {
              final data = jsonDecode(response.body);

              List? books;

              if (data['books'] != null) {
                books = data['books'] as List?;
              } else if (data is List) {
                books = data;
              } else if (data['data'] != null) {
                books = data['data'] as List?;
              }

              if (books != null && books.isNotEmpty) {
                filesLoaded++;
                consecutiveErrors = 0;

                for (var i = 0; i < books.length; i++) {
                  final book = books[i];

                  try {
                    final title = book['title'] ?? book['name'] ?? 'Sem título';

                    final normalizedBook = {
                      'id': book['id'] ?? book['isbn'] ?? 'book_${_currentFile}_$i',
                      'title': title,
                      'author': book['author'] ?? book['authors'] ?? 'Autor desconhecido',
                      'category': book['category'] ?? book['genre'] ?? 'Outros',
                      'coverImageURL': book['coverImageURL'] ?? book['coverImage'] ?? book['image'] ?? book['imageUrl'],
                      'description': book['description'] ?? book['summary'] ?? '',
                      'digitalPrice': book['digitalPrice'] ?? book['price'] ?? book['priceDigital'],
                      'physicalPrice': book['physicalPrice'] ?? book['pricePhysical'],
                      'rating': book['rating'] ?? book['averageRating'],
                      'pages': book['pages'] ?? book['pageCount'],
                      'publisher': book['publisher'],
                      'publishedDate': book['publishedDate'] ?? book['publicationDate'],
                      'language': book['language'] ?? 'pt',
                      'isbn': book['isbn'],
                      'format': book['format'] ?? ['Digital'],
                      'inStock': book['inStock'] ?? true,
                    };

                    if (normalizedBook['title'] != 'Sem título') {
                      loadedBooks.add(normalizedBook);
                    }

                  } catch (e) {
                    // Skip invalid book
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

      if (loadedBooks.isEmpty) {
        if (allBooks.isEmpty) {
          if (mounted) {
            setState(() {
              error = 'Nenhum livro disponível no momento.\nVerifique sua conexão e tente novamente.';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            allBooks.addAll(loadedBooks);
          });
        }
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
    return allBooks.where((book) {
      final bookCategory = book['category'] as String?;
      return bookCategory == selectedCategory;
    }).toList();
  }

  List<List<Map<String, dynamic>>> _getBooksInGroups() {
    final books = filteredBooks;
    List<List<Map<String, dynamic>>> groups = [];

    if (selectedCategory == 'Todos') {
      final categoryMap = <String, List<Map<String, dynamic>>>{};

      for (var book in books) {
        final cat = book['category'] ?? 'Outros';
        categoryMap.putIfAbsent(cat, () => []);
        categoryMap[cat]!.add(book);
      }

      categoryMap.forEach((category, booksInCat) {
        if (booksInCat.length >= 3) {
          groups.add(booksInCat);
        }
      });

      if (groups.isEmpty && books.isNotEmpty) {
        groups.add(books);
      }
    } else {
      for (var i = 0; i < books.length; i += 6) {
        final end = (i + 6 < books.length) ? i + 6 : books.length;
        groups.add(books.sublist(i, end));
      }
    }

    return groups;
  }

  String _getGroupTitle(List<Map<String, dynamic>> group, int index) {
    if (selectedCategory == 'Todos' && group.isNotEmpty) {
      return group[0]['category'] ?? 'Outros';
    }
    return 'Grupo ${index + 1}';
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
        controller: _scrollController,
        slivers: [
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
                      Text(
                        'Erro ao carregar livros',
                        style: TextStyle(
                          fontSize: 18,
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: hintColor),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchAllBooks,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      'Nenhum livro nesta categoria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tente selecionar outra categoria',
                      style: TextStyle(fontSize: 14, color: hintColor),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        setState(() => selectedCategory = 'Todos');
                      },
                      child: const Text('Ver todos os livros'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, groupIndex) {
                  final groups = _getBooksInGroups();
                  if (groupIndex >= groups.length) return null;

                  final group = groups[groupIndex];
                  final groupTitle = _getGroupTitle(group, groupIndex);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              groupTitle,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1877F2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${group.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1877F2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        height: 280,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(50 * (1 - value), 0),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: group.length,
                            itemBuilder: (context, index) {
                              final book = group[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: _buildBookCard(
                                  book,
                                  isDark,
                                  cardColor,
                                  textColor,
                                  hintColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  );
                },
                childCount: _getBooksInGroups().length,
              ),
            ),

          if (isLoadingMore)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Carregando mais livros...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
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
                            color: isDark
                                ? const Color(0xFF3A3B3C)
                                : const Color(0xFFF0F2F5),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1877F2),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (ctx, err, st) {
                          return Container(
                            color: isDark
                                ? const Color(0xFF3A3B3C)
                                : const Color(0xFFF0F2F5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: hintColor,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Capa\nindisponível',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: hintColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: isDark
                            ? const Color(0xFF3A3B3C)
                            : const Color(0xFFF0F2F5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 48,
                              color: hintColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sem capa',
                              style: TextStyle(
                                fontSize: 12,
                                color: hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book['title'] ?? 'Sem título',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book['author'] ?? 'Autor desconhecido',
                          style: TextStyle(
                            fontSize: 11,
                            color: hintColor,
                            height: 1.2,
                          ),
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1877F2),
                            ),
                          )
                        else
                          Text(
                            'Consultar',
                            style: TextStyle(
                              fontSize: 11,
                              color: hintColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (book['rating'] != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                book['rating'].toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
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

  Widget _buildCategoryChip(
    String name,
    String iconSvg,
    int count,
    bool isSelected,
    bool isDark,
    Color textColor,
    Color hintColor,
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
              : (isDark 
                  ? const Color(0xFF3A3B3C) 
                  : const Color(0xFFE4E6EB)),
          borderRadius: BorderRadius.circular(20),
          border: !isSelected && !isDark
              ? Border.all(color: const Color(0xFFCED0D4), width: 1)
              : null,
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
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? textColor : const Color(0xFF050505)),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : blueColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : blueColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
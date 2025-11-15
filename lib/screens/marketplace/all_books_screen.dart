// lib/screens/marketplace/all_books_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_icons.dart';
import 'book_details_screen.dart';

class AllBooksScreen extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> books;

  const AllBooksScreen({
    super.key,
    required this.title,
    required this.books,
  });

  @override
  State<AllBooksScreen> createState() => _AllBooksScreenState();
}

class _AllBooksScreenState extends State<AllBooksScreen> {
  String _sortBy = 'default'; // default, price_low, price_high, rating, title
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredAndSortedBooks {
    var books = widget.books.where((book) {
      if (_searchQuery.isEmpty) return true;
      final title = (book['title'] ?? '').toString().toLowerCase();
      final author = (book['author'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || author.contains(query);
    }).toList();

    // Ordenação
    switch (_sortBy) {
      case 'price_low':
        books.sort((a, b) {
          final priceA = a['digitalPrice'] ?? double.infinity;
          final priceB = b['digitalPrice'] ?? double.infinity;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_high':
        books.sort((a, b) {
          final priceA = a['digitalPrice'] ?? 0;
          final priceB = b['digitalPrice'] ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'rating':
        books.sort((a, b) {
          final ratingA = a['rating'] ?? 0;
          final ratingB = b['rating'] ?? 0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'title':
        books.sort((a, b) {
          final titleA = a['title'] ?? '';
          final titleB = b['title'] ?? '';
          return titleA.compareTo(titleB);
        });
        break;
    }

    return books;
  }

  void _showSortOptions(BuildContext context, Color cardColor, Color textColor, Color hintColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    color: hintColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Ordenar por',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSortOption('Padrão', 'default', Icons.apps, textColor, hintColor),
                _buildSortOption('Menor Preço', 'price_low', Icons.arrow_downward, textColor, hintColor),
                _buildSortOption('Maior Preço', 'price_high', Icons.arrow_upward, textColor, hintColor),
                _buildSortOption('Melhor Avaliação', 'rating', Icons.star, textColor, hintColor),
                _buildSortOption('Título (A-Z)', 'title', Icons.sort_by_alpha, textColor, hintColor),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon, Color textColor, Color hintColor) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF1877F2) : hintColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? const Color(0xFF1877F2) : textColor,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF1877F2))
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final books = _filteredAndSortedBooks;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: SvgPicture.string(
                      CustomIcons.arrowLeft,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.sort, color: textColor),
                    onPressed: () => _showSortOptions(context, cardColor, textColor, hintColor),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Buscar livros...',
                  hintStyle: TextStyle(color: hintColor),
                  prefixIcon: Icon(Icons.search, color: hintColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: hintColor),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${books.length} ${books.length == 1 ? "livro" : "livros"}',
                    style: TextStyle(
                      fontSize: 14,
                      color: hintColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_sortBy != 'default')
                    Text(
                      _getSortLabel(),
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF1877F2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grid de livros
            Expanded(
              child: books.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: hintColor),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum livro encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente outro termo de busca',
                            style: TextStyle(fontSize: 14, color: hintColor),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.55,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _buildBookCard(book, isDark, cardColor, textColor, hintColor);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'price_low':
        return 'Menor preço';
      case 'price_high':
        return 'Maior preço';
      case 'rating':
        return 'Melhor avaliação';
      case 'title':
        return 'A-Z';
      default:
        return '';
    }
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
              child: AspectRatio(
                aspectRatio: 0.7,
                child: book['coverImageURL'] != null
                    ? Image.network(
                        book['coverImageURL'],
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                          child: Icon(Icons.broken_image, color: hintColor, size: 48),
                        ),
                      )
                    : Container(
                        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                        child: Icon(Icons.menu_book, size: 48, color: hintColor),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
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
                          style: TextStyle(
                            fontSize: 14,
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
                            fontSize: 12,
                            color: hintColor,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (book['rating'] != null)
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Color(0xFFFFB800)),
                              const SizedBox(width: 4),
                              Text(
                                book['rating'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        if (book['digitalPrice'] != null)
                          Text(
                            '${book['digitalPrice']} Kz',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1877F2),
                            ),
                          )
                        else
                          Text(
                            'Consultar',
                            style: TextStyle(
                              fontSize: 12,
                              color: hintColor,
                              fontWeight: FontWeight.w600,
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
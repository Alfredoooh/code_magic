// lib/screens/marketplace/book_details_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';

class BookDetailsScreen extends StatelessWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  const BookDetailsScreen({
    super.key,
    required this.bookId,
    required this.bookData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final hasPhysical = bookData['hasPhysicalVersion'] == true;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // AppBar com imagem de fundo
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: cardColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: bookData['coverImageURL'] != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        bookData['coverImageURL'].toString().startsWith('data:image')
                            ? Image.memory(
                                base64Decode(bookData['coverImageURL'].split(',')[1]),
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                bookData['coverImageURL'],
                                fit: BoxFit.cover,
                              ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                bgColor.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                      child: Icon(
                        Icons.menu_book,
                        size: 100,
                        color: hintColor,
                      ),
                    ),
            ),
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: Container(
              color: bgColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    bookData['title'] ?? 'Sem título',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Autor
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: hintColor),
                      const SizedBox(width: 6),
                      Text(
                        bookData['author'] ?? 'Autor desconhecido',
                        style: TextStyle(
                          fontSize: 16,
                          color: hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Categoria
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1877F2).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      bookData['category'] ?? 'Categoria',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1877F2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preços
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.download, size: 20, color: hintColor),
                            const SizedBox(width: 8),
                            Text(
                              'Versão Digital',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${bookData['digitalPrice'] ?? 0} Kz',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1877F2),
                          ),
                        ),
                        Text(
                          'Formato: ${bookData['digitalFormat'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: hintColor,
                          ),
                        ),
                        if (hasPhysical) ...[
                          const SizedBox(height: 16),
                          Divider(color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.local_shipping_outlined, size: 20, color: hintColor),
                              const SizedBox(width: 8),
                              Text(
                                'Versão Física',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${bookData['physicalPrice'] ?? 0} Kz',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          if (bookData['weight'] != null)
                            Text(
                              'Peso: ${bookData['weight']}',
                              style: TextStyle(
                                fontSize: 13,
                                color: hintColor,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Descrição
                  Text(
                    'Descrição',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bookData['description'] ?? 'Sem descrição disponível.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detalhes
                  Text(
                    'Detalhes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        if (bookData['pages'] != null && bookData['pages'] != 0)
                          _buildDetailRow('Páginas', '${bookData['pages']}', hintColor, textColor),
                        if (bookData['publisher'] != null && bookData['publisher'].toString().isNotEmpty)
                          _buildDetailRow('Editora', bookData['publisher'], hintColor, textColor),
                        if (bookData['publicationYear'] != null && bookData['publicationYear'].toString().isNotEmpty)
                          _buildDetailRow('Ano', bookData['publicationYear'], hintColor, textColor),
                        if (bookData['isbn'] != null && bookData['isbn'].toString().isNotEmpty)
                          _buildDetailRow('ISBN', bookData['isbn'], hintColor, textColor),
                        if (bookData['language'] != null && bookData['language'].toString().isNotEmpty)
                          _buildDetailRow('Idioma', bookData['language'], hintColor, textColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vendedor
                  Text(
                    'Vendedor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF1877F2),
                          child: Text(
                            (bookData['sellerName'] ?? 'V').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookData['sellerName'] ?? 'Vendedor',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Vendedor verificado',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info sobre download
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF31A24C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF31A24C).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF31A24C)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bookData['downloadInfo'] ?? 'Informações de download não disponíveis.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Adicionar aos favoritos
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
                    );
                  },
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Favoritar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1877F2),
                    side: const BorderSide(color: Color(0xFF1877F2)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showPurchaseDialog(context, cardColor, textColor, hintColor);
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Comprar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color hintColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: hintColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showPurchaseDialog(BuildContext context, Color cardColor, Color textColor, Color hintColor) {
    final hasPhysical = bookData['hasPhysicalVersion'] == true;
    String selectedVersion = 'digital';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Escolher versão',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(
                  'Versão Digital',
                  style: TextStyle(color: textColor),
                ),
                subtitle: Text(
                  '${bookData['digitalPrice']} Kz',
                  style: const TextStyle(
                    color: Color(0xFF1877F2),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: 'digital',
                groupValue: selectedVersion,
                activeColor: const Color(0xFF1877F2),
                onChanged: (value) {
                  setState(() => selectedVersion = value!);
                },
              ),
              if (hasPhysical)
                RadioListTile<String>(
                  title: Text(
                    'Versão Física',
                    style: TextStyle(color: textColor),
                  ),
                  subtitle: Text(
                    '${bookData['physicalPrice']} Kz',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: 'physical',
                  groupValue: selectedVersion,
                  activeColor: const Color(0xFF1877F2),
                  onChanged: (value) {
                    setState(() => selectedVersion = value!);
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: hintColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Processando compra da versão ${selectedVersion == 'digital' ? 'digital' : 'física'}...',
                    ),
                    backgroundColor: const Color(0xFF31A24C),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
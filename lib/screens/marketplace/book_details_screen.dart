// lib/screens/marketplace/book_details_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_icons.dart';

class BookDetailsScreen extends StatefulWidget {
  final String bookId;
  final Map<String, dynamic> bookData;

  const BookDetailsScreen({
    super.key,
    required this.bookId,
    required this.bookData,
  });

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool _isFavorite = false;
  int _selectedChapter = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final hasPhysical = widget.bookData['hasPhysicalVersion'] == true;
    final inStock = widget.bookData['inStock'] == true;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Header com imagem e botões
          SliverToBoxAdapter(
            child: Container(
              color: cardColor,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Row(
                            children: [
                              IconButton(
                                icon: SvgPicture.string(
                                  CustomIcons.share,
                                  width: 24,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Compartilhar livro')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: _isFavorite ? Colors.red : textColor,
                                  size: 24,
                                ),
                                onPressed: () {
                                  setState(() => _isFavorite = !_isFavorite);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _isFavorite ? 'Adicionado aos favoritos' : 'Removido dos favoritos',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Imagem do livro
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Hero(
                        tag: 'book_${widget.bookId}',
                        child: Container(
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: widget.bookData['coverImageURL'] != null
                                ? (widget.bookData['coverImageURL'].toString().startsWith('data:image')
                                    ? Image.memory(
                                        base64Decode(widget.bookData['coverImageURL'].split(',')[1]),
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        widget.bookData['coverImageURL'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE8E8E8),
                                            child: Center(
                                              child: SvgPicture.string(
                                                CustomIcons.book,
                                                width: 80,
                                                height: 80,
                                                colorFilter: ColorFilter.mode(hintColor, BlendMode.srcIn),
                                              ),
                                            ),
                                          );
                                        },
                                      ))
                                : Container(
                                    color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE8E8E8),
                                    child: Center(
                                      child: SvgPicture.string(
                                        CustomIcons.book,
                                        width: 80,
                                        height: 80,
                                        colorFilter: ColorFilter.mode(hintColor, BlendMode.srcIn),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),

                    // Rating e categoria
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.bookData['rating'] != null) ...[
                            const Icon(Icons.star, color: Color(0xFFFFC107), size: 20),
                            const SizedBox(width: 4),
                            Text(
                              widget.bookData['rating'].toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.bookData['category'] ?? 'Categoria',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1877F2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                  // Título e autor
                  Text(
                    widget.bookData['title'] ?? 'Sem título',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SvgPicture.string(
                        CustomIcons.person,
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(hintColor, BlendMode.srcIn),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.bookData['author'] ?? 'Autor desconhecido',
                        style: TextStyle(
                          fontSize: 15,
                          color: hintColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botões de ação principais
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.bookData['readLink'] != null
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Abrindo leitor...'),
                                      backgroundColor: Color(0xFF1877F2),
                                    ),
                                  );
                                }
                              : null,
                          icon: SvgPicture.string(
                            CustomIcons.book,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          label: const Text('Ler Agora'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1877F2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showPurchaseDialog(context, cardColor, textColor, hintColor),
                          icon: SvgPicture.string(
                            CustomIcons.shoppingCart,
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(Color(0xFF1877F2), BlendMode.srcIn),
                          ),
                          label: const Text('Comprar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1877F2),
                            side: const BorderSide(color: Color(0xFF1877F2), width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Preços
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.download, size: 20, color: hintColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Digital',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.bookData['digitalPrice'] ?? 0} Kz',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            if (hasPhysical)
                              Container(
                                width: 1,
                                height: 50,
                                color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE5E5E5),
                              ),
                            if (hasPhysical)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.menu_book, size: 20, color: hintColor),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Físico',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.bookData['physicalPrice'] ?? 0} Kz',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        if (hasPhysical) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: inStock
                                  ? const Color(0xFF31A24C).withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  inStock ? Icons.check_circle : Icons.access_time,
                                  size: 16,
                                  color: inStock ? const Color(0xFF31A24C) : Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  inStock ? 'Em estoque' : 'Sob encomenda',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: inStock ? const Color(0xFF31A24C) : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Preview/Capítulos
                  if (widget.bookData['preview'] != null) ...[
                    Row(
                      children: [
                        SvgPicture.string(
                          CustomIcons.book,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Prévia do Livro',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bookData['preview'],
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: textColor,
                            ),
                            maxLines: 8,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: Text(
                                    'Prévia Completa',
                                    style: TextStyle(color: textColor),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Text(
                                      widget.bookData['preview'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.expand_more, size: 20),
                            label: const Text('Ler mais'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1877F2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Descrição
                  Row(
                    children: [
                      Icon(Icons.description_outlined, size: 20, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        'Sobre o Livro',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      widget.bookData['description'] ?? 'Sem descrição disponível.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detalhes técnicos
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: textColor),
                      const SizedBox(width: 8),
                      Text(
                        'Detalhes Técnicos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        if (widget.bookData['pages'] != null)
                          _buildDetailRow(
                            Icons.description,
                            'Páginas',
                            '${widget.bookData['pages']}',
                            hintColor,
                            textColor,
                          ),
                        if (widget.bookData['publisher'] != null)
                          _buildDetailRow(
                            Icons.business,
                            'Editora',
                            widget.bookData['publisher'],
                            hintColor,
                            textColor,
                          ),
                        if (widget.bookData['publishedDate'] != null)
                          _buildDetailRow(
                            Icons.calendar_today,
                            'Publicação',
                            widget.bookData['publishedDate'].toString().substring(0, 4),
                            hintColor,
                            textColor,
                          ),
                        if (widget.bookData['language'] != null)
                          _buildDetailRow(
                            Icons.language,
                            'Idioma',
                            _getLanguageName(widget.bookData['language']),
                            hintColor,
                            textColor,
                          ),
                        if (widget.bookData['isbn'] != null)
                          _buildDetailRow(
                            Icons.qr_code,
                            'ISBN',
                            widget.bookData['isbn'],
                            hintColor,
                            textColor,
                            isLast: true,
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
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color hintColor,
    Color textColor, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: hintColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: hintColor,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: hintColor.withOpacity(0.2),
            height: 1,
          ),
      ],
    );
  }

  String _getLanguageName(String code) {
    final languages = {
      'pt': 'Português',
      'en': 'Inglês',
      'es': 'Espanhol',
      'fr': 'Francês',
      'de': 'Alemão',
    };
    return languages[code] ?? code.toUpperCase();
  }

  void _showPurchaseDialog(BuildContext context, Color cardColor, Color textColor, Color hintColor) {
    final hasPhysical = widget.bookData['hasPhysicalVersion'] == true;
    String selectedVersion = 'digital';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SvgPicture.string(
                  CustomIcons.shoppingCart,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(Color(0xFF1877F2), BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Escolher Versão',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildVersionOption(
                'digital',
                selectedVersion,
                'Versão Digital',
                '${widget.bookData['digitalPrice']} Kz',
                'Download imediato',
                Icons.download,
                setState,
                textColor,
                hintColor,
              ),
              if (hasPhysical) ...[
                const SizedBox(height: 12),
                _buildVersionOption(
                  'physical',
                  selectedVersion,
                  'Versão Física',
                  '${widget.bookData['physicalPrice']} Kz',
                  'Entrega em 3-5 dias',
                  Icons.local_shipping,
                  setState,
                  textColor,
                  hintColor,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: hintColor, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
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
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text('Confirmar Compra'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1877F2),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionOption(
    String value,
    String groupValue,
    String title,
    String price,
    String subtitle,
    IconData icon,
    StateSetter setState,
    Color textColor,
    Color hintColor,
  ) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => setState(() => groupValue = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1877F2).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1877F2)
                : hintColor.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFF1877F2),
              onChanged: (v) => setState(() => groupValue = v!),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: isSelected ? const Color(0xFF1877F2) : hintColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFF1877F2) : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
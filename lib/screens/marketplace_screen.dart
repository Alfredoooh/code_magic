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

  // URL da sua API
  static const String _apiBaseUrl = 'https://data-ekoe.onrender.com';

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
    print('🌐 API: $_apiBaseUrl');
    print('♾️ Modo infinito ativado');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final List<Map<String, dynamic>> loadedBooks = [];
    int consecutiveErrors = 0;
    int filesLoaded = 0;
    int currentFile = 1;
    const maxConsecutiveErrors = 3;
    const maxFiles = 20;

    try {
      // Busca livros até encontrar 3 erros consecutivos ou atingir limite
      while (consecutiveErrors < maxConsecutiveErrors && filesLoaded < maxFiles) {
        final url = '$_apiBaseUrl/books/book$currentFile.json';
        print('🔍 Tentando: book$currentFile.json');
        print('   URL: $url');

        try {
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 15));

          print('   Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            try {
              final data = jsonDecode(response.body);
              print('   ✅ JSON parseado com sucesso');
              print('   Estrutura: ${data.keys.toList()}');

              // Tenta diferentes formatos possíveis
              List? books;
              
              // Formato 1: { "books": [...] }
              if (data['books'] != null) {
                books = data['books'] as List?;
              }
              // Formato 2: Array direto [...]
              else if (data is List) {
                books = data;
              }
              // Formato 3: { "data": [...] }
              else if (data['data'] != null) {
                books = data['data'] as List?;
              }

              if (books != null && books.isNotEmpty) {
                print('   ✅ ${books.length} livros encontrados');
                filesLoaded++;
                consecutiveErrors = 0;

                // Processa cada livro
                for (var i = 0; i < books.length; i++) {
                  final book = books[i];
                  
                  try {
                    // Debug do livro
                    final title = book['title'] ?? book['name'] ?? 'Sem título';
                    print('   📖 Livro $i: ${title.length > 40 ? title.substring(0, 40) : title}...');
                    
                    // Normaliza os dados do livro
                    final normalizedBook = {
                      'id': book['id'] ?? book['isbn'] ?? 'book_${currentFile}_$i',
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

                    // Validação básica
                    if (normalizedBook['title'] != 'Sem título') {
                      loadedBooks.add(normalizedBook);
                      
                      if (normalizedBook['coverImageURL'] != null) {
                        print('      🖼️ Capa: ${normalizedBook['coverImageURL']}');
                      } else {
                        print('      ⚠️ Sem imagem de capa');
                      }
                      
                      if (normalizedBook['digitalPrice'] != null) {
                        print('      💰 Preço: ${normalizedBook['digitalPrice']} Kz');
                      }
                      
                      print('      ✅ Livro adicionado');
                    } else {
                      print('      ⚠️ Livro sem título válido, ignorado');
                    }
                    
                  } catch (e) {
                    print('      ❌ Erro ao processar livro: $e');
                  }
                }

                currentFile++;
              } else {
                print('   ⚠️ Array de livros vazio ou não encontrado');
                consecutiveErrors++;
                currentFile++;
              }
              
            } catch (e) {
              print('   ❌ Erro ao fazer parse do JSON: $e');
              print('   Body (primeiros 300 caracteres):');
              final bodyPreview = response.body.length > 300 
                  ? response.body.substring(0, 300) 
                  : response.body;
              print('   $bodyPreview...');
              consecutiveErrors++;
              currentFile++;
            }
            
          } else if (response.statusCode == 404) {
            print('   ⚠️ Arquivo não existe (404)');
            consecutiveErrors++;
            currentFile++;
          } else {
            print('   ⚠️ Erro HTTP ${response.statusCode}');
            print('   Body: ${response.body}');
            consecutiveErrors++;
            currentFile++;
          }
          
        } catch (e) {
          print('   ❌ Erro de rede: $e');
          consecutiveErrors++;
          currentFile++;
        }

        // Pequeno delay entre requisições
        await Future.delayed(const Duration(milliseconds: 200));
      }

      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      if (loadedBooks.isEmpty) {
        print('❌ NENHUM LIVRO CARREGADO!');
        print('   Possíveis causas:');
        print('   1. API não está respondendo');
        print('   2. Formato JSON diferente do esperado');
        print('   3. Arquivos não existem no servidor');
        print('');
        print('   Próximo arquivo seria: book$currentFile.json');
        
        setState(() {
          error = 'Nenhum livro disponível no momento.\nVerifique sua conexão e tente novamente.';
          isLoading = false;
        });
      } else {
        print('✅ ${loadedBooks.length} LIVROS CARREGADOS COM SUCESSO!');
        print('📂 $filesLoaded arquivos processados');
        print('🔜 Próximo arquivo: book$currentFile.json');
        
        // Estatísticas
        final withImages = loadedBooks.where((b) => b['coverImageURL'] != null).length;
        final withPrice = loadedBooks.where((b) => b['digitalPrice'] != null).length;
        print('');
        print('📊 Estatísticas:');
        print('   🖼️ Com imagem: $withImages/${loadedBooks.length}');
        print('   💰 Com preço: $withPrice/${loadedBooks.length}');
        
        // Categorias únicas
        final categoriesSet = loadedBooks
            .map((b) => b['category'] as String?)
            .where((c) => c != null)
            .toSet();
        print('   📑 Categorias: ${categoriesSet.length} (${categoriesSet.join(", ")})');
        
        setState(() {
          allBooks = loadedBooks;
          isLoading = false;
        });
      }
      
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');
      
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ ERRO CRÍTICO: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      setState(() {
        error = 'Erro ao carregar livros: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredBooks {
    if (selectedCategory == 'Todos') return allBooks;
    return allBooks.where((book) {
      final bookCategory = book['category'] as String?;
      return bookCategory == selectedCategory;
    }).toList();
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
          // Header com informações
          SliverToBoxAdapter(
            child: Container(
              color: bgColor,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Marketplace',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${allBooks.length} ${allBooks.length == 1 ? 'livro disponível' : 'livros disponíveis'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLoading && allBooks.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.refresh, color: textColor),
                      onPressed: _fetchAllBooks,
                      tooltip: 'Atualizar',
                    ),
                ],
              ),
            ),
          ),

          // Categorias
          SliverToBoxAdapter(
            child: Container(
              color: bgColor,
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: categories.map((category) {
                    final bool isSelected = selectedCategory == category['name'];
                    final int count = category['name'] == 'Todos'
                        ? allBooks.length
                        : allBooks.where((b) => b['category'] == category['name']).length;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCategoryChip(
                        category['name'],
                        category['icon'],
                        count,
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
                      'Carregando livros da API...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Isso pode levar alguns segundos',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else if (error != null)
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
                            // Capa do livro
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
                                          print('❌ Erro ao carregar capa: $err');
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
                            
                            // Informações do livro
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
                                      )
                                    else
                                      Text(
                                        'Preço não disponível',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: hintColor,
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
    int count,
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
            if (count > 0 && !isLoading) ...[
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
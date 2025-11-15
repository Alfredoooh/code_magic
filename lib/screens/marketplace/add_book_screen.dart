// lib/screens/marketplace/add_book_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_icons.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _previewController = TextEditingController();
  final _digitalPriceController = TextEditingController();
  final _physicalPriceController = TextEditingController();
  final _pagesController = TextEditingController();
  final _weightController = TextEditingController();
  final _publisherController = TextEditingController();
  final _yearController = TextEditingController();
  final _isbnController = TextEditingController();
  final _languageController = TextEditingController(text: 'Português');
  final _readLinkController = TextEditingController();

  String? _selectedCategory;
  String? _selectedFormat;
  bool _hasPhysicalVersion = false;
  bool _isFree = false;
  bool _isLoading = false;
  File? _coverImageFile;
  bool _useImageUrl = false;
  final _coverImageUrlController = TextEditingController();
  double _rating = 0;

  final List<Map<String, String>> categories = [
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
    {'name': 'Produtividade', 'icon': CustomIcons.chartBar},
    {'name': 'Desenvolvimento Pessoal', 'icon': CustomIcons.userCircle},
    {'name': 'Psicologia', 'icon': CustomIcons.lightBulb},
    {'name': 'História', 'icon': CustomIcons.buildingLibrary},
    {'name': 'Liderança', 'icon': CustomIcons.userCircle},
    {'name': 'Educação', 'icon': CustomIcons.academicCap},
    {'name': 'Tecnologia', 'icon': CustomIcons.chartLine},
    {'name': 'Bem-estar', 'icon': CustomIcons.lightBulb},
    {'name': 'Arte', 'icon': CustomIcons.lightBulb},
  ];

  final List<String> formats = ['PDF', 'EPUB', 'MOBI', 'Word (DOCX)', 'Texto (TXT)'];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _previewController.dispose();
    _digitalPriceController.dispose();
    _physicalPriceController.dispose();
    _pagesController.dispose();
    _weightController.dispose();
    _publisherController.dispose();
    _yearController.dispose();
    _isbnController.dispose();
    _languageController.dispose();
    _coverImageUrlController.dispose();
    _readLinkController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _coverImageFile = File(image.path);
          _useImageUrl = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar imagem: $e')),
        );
      }
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      // Scroll para o primeiro erro
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma categoria')),
      );
      return;
    }

    if (_selectedFormat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um formato digital')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userData = authProvider.userData;

      String? coverImageUrl;
      if (_useImageUrl && _coverImageUrlController.text.trim().isNotEmpty) {
        coverImageUrl = _coverImageUrlController.text.trim();
      } else if (_coverImageFile != null) {
        coverImageUrl = 'pending_upload';
      }

      final bookData = {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'preview': _previewController.text.trim(),
        'category': _selectedCategory,
        'digitalFormat': _selectedFormat,
        'digitalPrice': _isFree ? 0 : (double.tryParse(_digitalPriceController.text.trim()) ?? 0),
        'isFree': _isFree,
        'physicalPrice': _hasPhysicalVersion ? (double.tryParse(_physicalPriceController.text.trim()) ?? 0) : null,
        'hasPhysicalVersion': _hasPhysicalVersion,
        'pages': int.tryParse(_pagesController.text.trim()),
        'weight': _weightController.text.trim(),
        'publisher': _publisherController.text.trim(),
        'publishedDate': _yearController.text.trim(),
        'isbn': _isbnController.text.trim(),
        'language': _languageController.text.trim(),
        'coverImageURL': coverImageUrl,
        'readLink': _readLinkController.text.trim(),
        'rating': _rating > 0 ? _rating : null,
        'sellerId': authProvider.user?.uid,
        'sellerName': userData?['name'] ?? 'Vendedor',
        'sellerEmail': userData?['email'],
        'format': [_selectedFormat, if (_hasPhysicalVersion) 'Físico'],
        'inStock': _hasPhysicalVersion,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'views': 0,
        'favorites': 0,
      };

      await FirebaseFirestore.instance.collection('books').add(bookData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Livro adicionado com sucesso!'),
            backgroundColor: Color(0xFF31A24C),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar livro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                      'Adicionar Livro',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton(
                      onPressed: _saveBook,
                      child: const Text(
                        'Publicar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1877F2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              color: isDark ? const Color(0xFF3E4042) : const Color(0xFFE5E5E5),
              height: 1,
            ),

            // Conteúdo
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Capa
                    _buildSection(
                      'Capa do Livro',
                      cardColor,
                      textColor,
                      child: Column(
                        children: [
                          Center(
                            child: GestureDetector(
                              onTap: _pickCoverImage,
                              child: Container(
                                width: 160,
                                height: 240,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF1877F2).withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  image: _coverImageFile != null
                                      ? DecorationImage(
                                          image: FileImage(_coverImageFile!),
                                          fit: BoxFit.cover,
                                        )
                                      : (_useImageUrl && _coverImageUrlController.text.isNotEmpty)
                                          ? DecorationImage(
                                              image: NetworkImage(_coverImageUrlController.text),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                ),
                                child: (_coverImageFile == null && (!_useImageUrl || _coverImageUrlController.text.isEmpty))
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.string(
                                            CustomIcons.photo,
                                            width: 48,
                                            height: 48,
                                            colorFilter: const ColorFilter.mode(
                                              Color(0xFF1877F2),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Adicionar Capa',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Toque para selecionar',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: hintColor,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: Divider(color: hintColor.withOpacity(0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('ou', style: TextStyle(fontSize: 13, color: hintColor)),
                              ),
                              Expanded(child: Divider(color: hintColor.withOpacity(0.3))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _coverImageUrlController,
                            style: TextStyle(color: textColor, fontSize: 14),
                            onChanged: (value) {
                              setState(() {
                                _useImageUrl = value.isNotEmpty;
                                if (value.isNotEmpty) _coverImageFile = null;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Cole URL da capa',
                              hintStyle: TextStyle(color: hintColor, fontSize: 14),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(Icons.link, color: hintColor, size: 20),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informações Básicas
                    _buildSection(
                      'Informações Básicas',
                      cardColor,
                      textColor,
                      child: Column(
                        children: [
                          _buildTextField('Título do Livro *', _titleController, textColor, hintColor, isDark, required: true),
                          const SizedBox(height: 16),
                          _buildTextField('Autor *', _authorController, textColor, hintColor, isDark, required: true),
                          const SizedBox(height: 16),
                          _buildTextField('Descrição *', _descriptionController, textColor, hintColor, isDark, maxLines: 4, required: true),
                          const SizedBox(height: 16),
                          _buildTextField('Prévia do Livro', _previewController, textColor, hintColor, isDark, maxLines: 6, 
                            hint: 'Adicione um trecho do livro para despertar interesse...'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Categoria
                    _buildSection(
                      'Categoria *',
                      cardColor,
                      textColor,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((category) {
                          final isSelected = _selectedCategory == category['name'];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = category['name']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? const Color(0xFF1877F2) 
                                    : (isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected 
                                      ? const Color(0xFF1877F2) 
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.string(
                                    category['icon']!,
                                    width: 16,
                                    height: 16,
                                    colorFilter: ColorFilter.mode(
                                      isSelected ? Colors.white : const Color(0xFF1877F2),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category['name']!,
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
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Formato e Preço
                    _buildSection(
                      'Formato e Preço',
                      cardColor,
                      textColor,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedFormat,
                            dropdownColor: cardColor,
                            style: TextStyle(color: textColor, fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Formato Digital *',
                              labelStyle: TextStyle(color: hintColor),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            items: formats.map((format) {
                              return DropdownMenuItem(value: format, child: Text(format));
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedFormat = value),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: Row(
                              children: [
                                Icon(Icons.card_giftcard, color: _isFree ? const Color(0xFF31A24C) : hintColor, size: 20),
                                const SizedBox(width: 12),
                                Text('Livro Grátis', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            value: _isFree,
                            activeColor: const Color(0xFF31A24C),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) => setState(() => _isFree = value),
                          ),
                          if (!_isFree) ...[
                            const SizedBox(height: 16),
                            _buildTextField('Preço Digital (Kz) *', _digitalPriceController, textColor, hintColor, isDark, 
                              keyboardType: TextInputType.number, required: true, prefix: 'Kz '),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Versão Física
                    _buildSection(
                      'Versão Física',
                      cardColor,
                      textColor,
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text('Possui versão física', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                            value: _hasPhysicalVersion,
                            activeColor: const Color(0xFF1877F2),
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) => setState(() => _hasPhysicalVersion = value),
                          ),
                          if (_hasPhysicalVersion) ...[
                            const SizedBox(height: 16),
                            _buildTextField('Preço Físico (Kz)', _physicalPriceController, textColor, hintColor, isDark, 
                              keyboardType: TextInputType.number, prefix: 'Kz '),
                            const SizedBox(height: 16),
                            _buildTextField('Peso (ex: 500g)', _weightController, textColor, hintColor, isDark),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Avaliação
                    _buildSection(
                      'Avaliação do Livro',
                      cardColor,
                      textColor,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () => setState(() => _rating = index + 1.0),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Icon(
                                    index < _rating ? Icons.star : Icons.star_border,
                                    color: const Color(0xFFFFB800),
                                    size: 36,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _rating > 0 ? '${_rating.toStringAsFixed(1)} estrelas' : 'Toque para avaliar',
                            style: TextStyle(fontSize: 14, color: hintColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detalhes Adicionais
                    _buildSection(
                      'Detalhes Adicionais',
                      cardColor,
                      textColor,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildTextField('Páginas', _pagesController, textColor, hintColor, isDark, keyboardType: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildTextField('Ano', _yearController, textColor, hintColor, isDark, keyboardType: TextInputType.number)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField('Editora', _publisherController, textColor, hintColor, isDark),
                          const SizedBox(height: 16),
                          _buildTextField('ISBN', _isbnController, textColor, hintColor, isDark),
                          const SizedBox(height: 16),
                          _buildTextField('Idioma', _languageController, textColor, hintColor, isDark),
                          const SizedBox(height: 16),
                          _buildTextField('Link de Leitura', _readLinkController, textColor, hintColor, isDark, 
                            hint: 'URL para ler o livro online (opcional)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1877F2).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF1877F2), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Após publicar, envie o arquivo do livro para nosso WhatsApp e receberá o link de download automaticamente.',
                              style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Color cardColor, Color textColor, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    Color textColor,
    Color hintColor,
    bool isDark, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
    String? prefix,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor, fontSize: 15),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo obrigatório';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: hintColor, fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(color: hintColor.withOpacity(0.7), fontSize: 13),
        prefixText: prefix,
        prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
// lib/screens/marketplace/add_book_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _digitalPriceController = TextEditingController();
  final _physicalPriceController = TextEditingController();
  final _pagesController = TextEditingController();
  final _weightController = TextEditingController();
  final _publisherController = TextEditingController();
  final _yearController = TextEditingController();
  final _isbnController = TextEditingController();
  final _languageController = TextEditingController();
  final _coverImageUrlController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedFormat;
  bool _hasPhysicalVersion = false;
  bool _isLoading = false;

  final List<String> categories = [
    'Ficção',
    'Não-Ficção',
    'Acadêmico',
    'Técnico',
    'Infantil',
    'Romance',
    'Biografia',
    'História',
    'Ciência',
    'Autoajuda',
    'Poesia',
  ];

  final List<String> formats = [
    'PDF',
    'EPUB',
    'MOBI',
    'Word (DOCX)',
    'Texto (TXT)',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _digitalPriceController.dispose();
    _physicalPriceController.dispose();
    _pagesController.dispose();
    _weightController.dispose();
    _publisherController.dispose();
    _yearController.dispose();
    _isbnController.dispose();
    _languageController.dispose();
    _coverImageUrlController.dispose();
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
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        _coverImageUrlController.text = base64Image;
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar imagem: $e')),
      );
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

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

      await FirebaseFirestore.instance.collection('marketplace_books').add({
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'digitalFormat': _selectedFormat,
        'digitalPrice': double.tryParse(_digitalPriceController.text.trim()) ?? 0,
        'physicalPrice': _hasPhysicalVersion ? (double.tryParse(_physicalPriceController.text.trim()) ?? 0) : null,
        'hasPhysicalVersion': _hasPhysicalVersion,
        'pages': int.tryParse(_pagesController.text.trim()) ?? 0,
        'weight': _weightController.text.trim(),
        'publisher': _publisherController.text.trim(),
        'publicationYear': _yearController.text.trim(),
        'isbn': _isbnController.text.trim(),
        'language': _languageController.text.trim(),
        'coverImageURL': _coverImageUrlController.text.trim(),
        'sellerId': authProvider.user?.uid,
        'sellerName': userData?['name'] ?? 'Vendedor',
        'sellerEmail': userData?['email'],
        'downloadInfo': 'Envie o livro para nosso WhatsApp e receberá o link de download automaticamente',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livro adicionado com sucesso!'),
            backgroundColor: Color(0xFF31A24C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar livro: $e')),
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
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Adicionar Livro',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Capa do livro
            Center(
              child: GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  width: 150,
                  height: 220,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                      width: 2,
                    ),
                    image: _coverImageUrlController.text.isNotEmpty
                        ? DecorationImage(
                            image: _coverImageUrlController.text.startsWith('data:image')
                                ? MemoryImage(base64Decode(_coverImageUrlController.text.split(',')[1]))
                                : NetworkImage(_coverImageUrlController.text) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _coverImageUrlController.text.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: hintColor),
                            const SizedBox(height: 8),
                            Text(
                              'Adicionar Capa',
                              style: TextStyle(fontSize: 12, color: hintColor),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _coverImageUrlController,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ou cole URL da capa',
                hintStyle: TextStyle(color: hintColor, fontSize: 13),
                filled: true,
                fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // Informações básicas
            _buildTextField('Título do Livro *', _titleController, textColor, hintColor, isDark, required: true),
            const SizedBox(height: 16),
            _buildTextField('Autor *', _authorController, textColor, hintColor, isDark, required: true),
            const SizedBox(height: 16),
            _buildTextField('Descrição *', _descriptionController, textColor, hintColor, isDark, maxLines: 4, required: true),
            const SizedBox(height: 16),

            // Categoria
            Text(
              'Categoria *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: cardColor,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: categories.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),

            // Formato digital
            Text(
              'Formato Digital *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFormat,
              dropdownColor: cardColor,
              style: TextStyle(color: textColor, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: formats.map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Text(format),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedFormat = value);
              },
            ),
            const SizedBox(height: 16),

            // Preços
            _buildTextField('Preço Digital (Kz) *', _digitalPriceController, textColor, hintColor, isDark, 
              keyboardType: TextInputType.number, required: true),
            const SizedBox(height: 16),

            // Versão física
            CheckboxListTile(
              title: Text('Possui versão física', style: TextStyle(color: textColor)),
              value: _hasPhysicalVersion,
              activeColor: const Color(0xFF1877F2),
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                setState(() => _hasPhysicalVersion = value ?? false);
              },
            ),
            if (_hasPhysicalVersion) ...[
              _buildTextField('Preço Físico (Kz)', _physicalPriceController, textColor, hintColor, isDark, 
                keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField('Peso (ex: 500g)', _weightController, textColor, hintColor, isDark),
              const SizedBox(height: 16),
            ],

            // Detalhes adicionais
            _buildTextField('Número de Páginas', _pagesController, textColor, hintColor, isDark, 
              keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField('Editora', _publisherController, textColor, hintColor, isDark),
            const SizedBox(height: 16),
            _buildTextField('Ano de Publicação', _yearController, textColor, hintColor, isDark, 
              keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField('ISBN', _isbnController, textColor, hintColor, isDark),
            const SizedBox(height: 16),
            _buildTextField('Idioma', _languageController, textColor, hintColor, isDark),
            const SizedBox(height: 24),

            // Info sobre download
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1877F2).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1877F2)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Envie o arquivo do livro para nosso WhatsApp e receberá o link de download automaticamente.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botão salvar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Adicionar Livro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor, fontSize: 15),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Este campo é obrigatório';
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
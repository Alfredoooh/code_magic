// lib/widgets/new_post_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

class NewPostModal extends StatefulWidget {
  const NewPostModal({super.key});

  @override
  State<NewPostModal> createState() => _NewPostModalState();
}

class _NewPostModalState extends State<NewPostModal> {
  final _contentController = TextEditingController();
  String _selectedCategory = 'geral';
  bool _isPosting = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    try {
      final authProvider = context.read<AuthProvider>();

      await FirebaseFirestore.instance.collection('posts').add({
        'authorId': authProvider.user?.uid ?? '',
        'authorName': authProvider.userData?['name'] ?? 'Usuário',
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Publicação criada com sucesso'),
            backgroundColor: Color(0xFF31A24C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar publicação: $e'),
            backgroundColor: const Color(0xFFFA383E),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final authProvider = context.watch<AuthProvider>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                      width: 0.3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                          size: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Criar publicação',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 32),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF1877F2),
                            backgroundImage: authProvider.userData?['photoURL'] != null
                                ? NetworkImage(authProvider.userData!['photoURL'])
                                : null,
                            child: authProvider.userData?['photoURL'] == null
                                ? Text(
                                    authProvider.userData?['name']?.substring(0, 1).toUpperCase() ?? 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authProvider.userData?['name'] ?? 'Usuário',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      isDense: true,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                                      ),
                                      dropdownColor: bgColor,
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        size: 16,
                                        color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'geral',
                                          child: Row(
                                            children: [
                                              Icon(Icons.public, size: 12),
                                              SizedBox(width: 4),
                                              Text('Público'),
                                            ],
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'marketplace',
                                          child: Row(
                                            children: [
                                              Icon(Icons.storefront, size: 12),
                                              SizedBox(width: 4),
                                              Text('Marketplace'),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() => _selectedCategory = value);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        minLines: 6,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'No que você está pensando?',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: isDark ? const Color(0xFF4E4F50) : const Color(0xFFBCC0C4),
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                      width: 0.3,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isPosting || _contentController.text.trim().isEmpty
                        ? null
                        : _createPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
                      disabledForegroundColor: isDark ? const Color(0xFF4E4F50) : const Color(0xFFBCC0C4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Publicar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
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
}
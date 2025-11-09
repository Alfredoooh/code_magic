// lib/screens/avatar_gallery_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import '../models/avatar_model.dart';
import '../widgets/custom_icons.dart';
import '../widgets/custom_snackbar.dart';

class AvatarGalleryScreen extends StatefulWidget {
  final String? currentAvatarUrl;

  const AvatarGalleryScreen({
    super.key,
    this.currentAvatarUrl,
  });

  @override
  State<AvatarGalleryScreen> createState() => _AvatarGalleryScreenState();
}

class _AvatarGalleryScreenState extends State<AvatarGalleryScreen> {
  List<AvatarImage> _avatars = [];
  bool _isLoading = true;
  String? _selectedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _selectedAvatarUrl = widget.currentAvatarUrl;
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    setState(() => _isLoading = true);

    try {
      // URL do JSON hospedado - SUBSTITUA PELA SUA URL REAL
      const avatarJsonUrl = 'https://raw.githubusercontent.com/yourusername/avatars/main/avatars.json';

      final response = await http.get(Uri.parse(avatarJsonUrl)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final avatarsList = data['avatars'] as List;
        
        if (avatarsList.isNotEmpty) {
          setState(() {
            _avatars = avatarsList
                .map((avatar) => AvatarImage.fromJson(avatar))
                .toList();
          });
        } else {
          // JSON vazio, sem avatares
          setState(() => _avatars = []);
        }
      } else {
        // Erro HTTP, sem avatares
        setState(() => _avatars = []);
      }
    } catch (e) {
      // Erro de rede ou timeout, sem avatares
      setState(() => _avatars = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          icon: SvgPicture.string(
            CustomIcons.arrowLeft,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Galeria de Avatares',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          if (_selectedAvatarUrl != null && _selectedAvatarUrl != widget.currentAvatarUrl)
            TextButton(
              onPressed: () {
                Navigator.pop(context, _selectedAvatarUrl);
              },
              child: const Text(
                'Confirmar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1877F2),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
              ),
            )
          : _avatars.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: isDark
                            ? const Color(0xFF3A3B3C)
                            : const Color(0xFFDADADA),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum avatar disponível',
                        style: TextStyle(
                          fontSize: 16,
                          color: hintColor,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF1877F2).withOpacity(0.1),
                              const Color(0xFF9C27B0).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF1877F2).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1877F2).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Color(0xFF1877F2),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_avatars.length} avatares disponíveis. Toque para selecionar.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: _avatars.length,
                        itemBuilder: (context, index) {
                          final avatar = _avatars[index];
                          final isSelected = _selectedAvatarUrl == avatar.imageUrl;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAvatarUrl = avatar.imageUrl;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1877F2)
                                      : (isDark
                                          ? const Color(0xFF3E4042)
                                          : const Color(0xFFDADADA)),
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.08),
                                    blurRadius: isSelected ? 12 : 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      avatar.imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Color(
                                            int.parse(
                                              'FF${avatar.color.replaceAll('#', '')}',
                                              radix: 16,
                                            ),
                                          ).withOpacity(0.3),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Color(0xFF1877F2),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Color(
                                            int.parse(
                                              'FF${avatar.color.replaceAll('#', '')}',
                                              radix: 16,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        );
                                      },
                                    ),
                                    if (isSelected)
                                      Container(
                                        color: const Color(0xFF1877F2).withOpacity(0.3),
                                        child: const Center(
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 36,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
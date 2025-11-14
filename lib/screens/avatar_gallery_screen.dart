// lib/screens/avatar_gallery_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import '../models/avatar_model.dart';
import '../widgets/custom_icons.dart';
import '../widgets/search_avatar_screen.dart';

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
  bool _isLoadingMore = false;
  String? _selectedAvatarUrl;
  int _currentFile = 1;
  bool _hasMoreAvatars = true;
  final ScrollController _scrollController = ScrollController();

  static const _apiBaseUrl = 'https://raw.githubusercontent.com/Alfredoooh/data-server/main/public';

  @override
  void initState() {
    super.initState();
    _selectedAvatarUrl = widget.currentAvatarUrl;
    _loadAvatars();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreAvatars) {
        _loadMoreAvatars();
      }
    }
  }

  Future<void> _loadAvatars() async {
    setState(() {
      _isLoading = true;
      _currentFile = 1;
      _hasMoreAvatars = true;
      _avatars.clear();
    });

    await _fetchAvatarsFromAPI();
    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreAvatars() async {
    if (_isLoadingMore || !_hasMoreAvatars) return;
    setState(() => _isLoadingMore = true);
    await _fetchAvatarsFromAPI();
    setState(() => _isLoadingMore = false);
  }

  Future<void> _fetchAvatarsFromAPI() async {
    int consecutiveErrors = 0;
    const maxConsecutiveErrors = 3;
    int filesLoaded = 0;
    final List<AvatarImage> loadedAvatars = [];

    try {
      while (consecutiveErrors < maxConsecutiveErrors && filesLoaded < 5) {
        final url = '$_apiBaseUrl/avatars/avatar$_currentFile.json';

        try {
          final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            try {
              final data = json.decode(response.body);
              final List? avatarsList = data['avatars'];

              if (avatarsList != null && avatarsList.isNotEmpty) {
                filesLoaded++;
                consecutiveErrors = 0;

                for (var i = 0; i < avatarsList.length; i++) {
                  try {
                    final avatar = AvatarImage.fromJson(avatarsList[i]);
                    loadedAvatars.add(avatar);
                  } catch (e) {
                    debugPrint('Erro ao processar avatar: $e');
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
        _hasMoreAvatars = false;
      }

      if (loadedAvatars.isNotEmpty) {
        setState(() {
          _avatars.addAll(loadedAvatars);
        });
      }
    } catch (e) {
      debugPrint('Erro crítico: $e');
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
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Galeria de Avatares',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1877F2),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
              ),
            )
          : _avatars.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: () async {
                          final selected = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchAvatarScreen(avatars: _avatars),
                            ),
                          );
                          if (selected != null) {
                            setState(() => _selectedAvatarUrl = selected);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.string(
                                CustomIcons.search,
                                width: 20,
                                height: 20,
                                colorFilter: ColorFilter.mode(hintColor, BlendMode.srcIn),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Pesquisar avatares...',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Grid de avatares - 2x2 com cards maiores
                    Expanded(
                      child: GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                        itemCount: _avatars.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _avatars.length) {
                            return const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                              ),
                            );
                          }

                          final avatar = _avatars[index];
                          final isSelected = _selectedAvatarUrl == avatar.imageUrl;

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedAvatarUrl = avatar.imageUrl);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1877F2)
                                      : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5)),
                                  width: isSelected ? 3 : 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF1877F2).withOpacity(0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      avatar.imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8E8),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE8E8E8),
                                          child: Center(
                                            child: SvgPicture.string(
                                              CustomIcons.person,
                                              width: 48,
                                              height: 48,
                                              colorFilter: ColorFilter.mode(
                                                hintColor,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (isSelected)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1877F2).withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 56,
                                            height: 56,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF1877F2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: SvgPicture.string(
                                                CustomIcons.check,
                                                width: 28,
                                                height: 28,
                                                colorFilter: const ColorFilter.mode(
                                                  Colors.white,
                                                  BlendMode.srcIn,
                                                ),
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
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
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
  bool _isLoadingMore = false;
  String? _selectedAvatarUrl;
  int _currentFile = 1;
  bool _hasMoreAvatars = true;
  final ScrollController _scrollController = ScrollController();

  // NOVO ENDPOINT DO GITHUB
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

    print('');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎭 CARREGANDO AVATARES DA API...');
    print('🌐 API: $_apiBaseUrl');
    print('♾️ Sistema infinito ativado');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    await _fetchAvatarsFromAPI();

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreAvatars() async {
    if (_isLoadingMore || !_hasMoreAvatars) return;

    setState(() => _isLoadingMore = true);

    print('📥 Carregando mais avatares...');
    await _fetchAvatarsFromAPI();

    setState(() => _isLoadingMore = false);
  }

  Future<void> _fetchAvatarsFromAPI() async {
    int consecutiveErrors = 0;
    const maxConsecutiveErrors = 3;
    int filesLoaded = 0;
    final List<AvatarImage> loadedAvatars = [];

    try {
      // Carrega até encontrar 3 erros consecutivos
      while (consecutiveErrors < maxConsecutiveErrors && filesLoaded < 5) {
        final url = '$_apiBaseUrl/avatars/avatar$_currentFile.json';
        print('🔍 Tentando: avatar$_currentFile.json');
        print('   URL: $url');

        try {
          final response = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 10));

          print('   Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            try {
              final data = json.decode(response.body);
              print('   ✅ JSON parseado com sucesso');

              final List? avatarsList = data['avatars'];

              if (avatarsList != null && avatarsList.isNotEmpty) {
                print('   ✅ ${avatarsList.length} avatares encontrados');
                filesLoaded++;
                consecutiveErrors = 0;

                for (var i = 0; i < avatarsList.length; i++) {
                  try {
                    final avatar = AvatarImage.fromJson(avatarsList[i]);
                    loadedAvatars.add(avatar);
                    print('      🎭 Avatar $i: ${avatar.name}');
                  } catch (e) {
                    print('      ❌ Erro ao processar avatar $i: $e');
                  }
                }

                _currentFile++;
              } else {
                print('   ⚠️ Array de avatares vazio');
                consecutiveErrors++;
                _currentFile++;
              }
            } catch (e) {
              print('   ❌ Erro ao fazer parse do JSON: $e');
              consecutiveErrors++;
              _currentFile++;
            }
          } else if (response.statusCode == 404) {
            print('   ⚠️ Arquivo não existe (404)');
            consecutiveErrors++;
          } else {
            print('   ⚠️ Erro HTTP ${response.statusCode}');
            consecutiveErrors++;
            _currentFile++;
          }
        } catch (e) {
          print('   ❌ Erro de rede: $e');
          consecutiveErrors++;
          if (consecutiveErrors < maxConsecutiveErrors) {
            _currentFile++;
          }
        }

        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (consecutiveErrors >= maxConsecutiveErrors) {
        print('🛑 Limite de erros atingido - Fim dos avatares');
        _hasMoreAvatars = false;
      }

      print('');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (loadedAvatars.isNotEmpty) {
        print('✅ ${loadedAvatars.length} NOVOS AVATARES CARREGADOS!');
        print('📂 $filesLoaded arquivos processados');
        print('📦 Total de avatares: ${_avatars.length + loadedAvatars.length}');
        print('🔜 Próximo arquivo: avatar$_currentFile.json');

        setState(() {
          _avatars.addAll(loadedAvatars);
        });
      } else {
        print('⚠️ Nenhum avatar novo carregado');
        if (_avatars.isEmpty) {
          print('❌ Nenhum avatar disponível');
        }
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('');

    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ ERRO CRÍTICO: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Carregando avatares...',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
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
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadAvatars,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar Novamente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          foregroundColor: Colors.white,
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
                                '${_avatars.length} avatares disponíveis. Role para carregar mais.',
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
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: _avatars.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _avatars.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1877F2),
                                  ),
                                ),
                              ),
                            );
                          }

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
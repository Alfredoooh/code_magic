// lib/screens/search_avatar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/avatar_model.dart';
import '../widgets/custom_icons.dart';

class SearchAvatarScreen extends StatefulWidget {
  final List<AvatarImage> avatars;

  const SearchAvatarScreen({
    super.key,
    required this.avatars,
  });

  @override
  State<SearchAvatarScreen> createState() => _SearchAvatarScreenState();
}

class _SearchAvatarScreenState extends State<SearchAvatarScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<AvatarImage> _filteredAvatars = [];

  @override
  void initState() {
    super.initState();
    _filteredAvatars = widget.avatars;
    _searchFocus.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _filterAvatars(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredAvatars = widget.avatars;
      } else {
        _filteredAvatars = widget.avatars.where((avatar) {
          return avatar.name.toLowerCase().contains(query.toLowerCase()) ||
              avatar.category.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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
        backgroundColor: bgColor,
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
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Pesquisar avatares...',
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.string(
                  CustomIcons.search,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(hintColor, BlendMode.srcIn),
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: SvgPicture.string(
                        CustomIcons.close,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(hintColor, BlendMode.srcIn),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _filterAvatars('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: _filterAvatars,
          ),
        ),
        titleSpacing: 0,
      ),
      body: _filteredAvatars.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.string(
                    CustomIcons.search,
                    width: 64,
                    height: 64,
                    colorFilter: ColorFilter.mode(
                      hintColor.withOpacity(0.5),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum avatar encontrado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tente usar outros termos de pesquisa',
                    style: TextStyle(
                      fontSize: 14,
                      color: hintColor,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _filteredAvatars.length,
              itemBuilder: (context, index) {
                final avatar = _filteredAvatars[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, avatar.imageUrl);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        avatar.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF0F2F5),
                            child: Center(
                              child: SvgPicture.string(
                                CustomIcons.person,
                                width: 32,
                                height: 32,
                                colorFilter: ColorFilter.mode(
                                  hintColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
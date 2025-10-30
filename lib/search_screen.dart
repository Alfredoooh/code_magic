import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

class SearchScreen extends StatefulWidget {
  final String token;

  const SearchScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final markets = ['R_100', 'R_50', 'R_25', 'R_75', 'BOOM500', 'BOOM1000', 'CRASH500'];
    setState(() {
      _searchResults = markets
          .where((m) => m.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surfaceContainer,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: context.textStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Pesquisar mercados...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: context.colors.onSurfaceVariant),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      AppHaptics.light();
                      setState(() {
                        _searchController.clear();
                        _searchResults = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
        ),
      ),
      body: _searchController.text.isEmpty
          ? EmptyState(
              icon: Icons.search_rounded,
              title: 'Pesquisar Mercados',
              subtitle: 'Digite para buscar mercados disponíveis',
            )
          : _searchResults.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Nenhum resultado',
                  subtitle: 'Tente buscar por outro termo',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return StaggeredListItem(
                      index: index,
                      delay: const Duration(milliseconds: 50),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: InfoCard(
                          icon: Icons.show_chart_rounded,
                          title: _searchResults[index],
                          subtitle: 'Mercado sintético',
                          color: AppColors.primary,
                          onTap: () {
                            AppHaptics.selection();
                            AppSnackbar.info(context, 'Mercado ${_searchResults[index]} selecionado');
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
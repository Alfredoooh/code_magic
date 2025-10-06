// lib/screens/dashboard_widgets/favorites_screen.dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/app_model.dart';
import '../../../services/app_service.dart';

class FavoritesScreen extends StatefulWidget {
  final List<AppModel> favoriteApps;
  final void Function(AppModel) onAppTap;

  /// Opcional: se passado, a persistência será feita por utilizador (recommended).
  /// Use o id do utilizador (por exemplo: user.id).
  final String? userId;

  const FavoritesScreen({
    Key? key,
    required this.favoriteApps,
    required this.onAppTap,
    this.userId,
  }) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final AppService _appService = AppService();
  late List<AppModel> _favoriteApps;
  bool _isEditMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // persistence
  late final String _prefsKey;
  bool _loadingPrefs = true;

  @override
  void initState() {
    super.initState();
    // inicializa lista com a cópia enviada (não modificar original)
    _favoriteApps = List<AppModel>.from(widget.favoriteApps);
    _prefsKey = widget.userId != null ? 'favorites_${widget.userId}' : 'favorites_global';
    _loadFavoritesFromPrefs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --------- Persistence helpers ----------
  Future<void> _loadFavoritesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefsKey);
      if (saved == null) {
        // nada guardado — inicializa campo com os passados pelo construtor
        await _saveFavoritesToPrefs(_favoriteApps.map((a) => a.id).toList());
        setState(() => _loadingPrefs = false);
        return;
      }

      // Guardado contém uma lista de IDs. Reconstrói usando os AppModel passados.
      final ids = saved.toSet();
      // Usa os AppModel fornecidos no widget.favoriteApps (assumimos que já tens os dados locais).
      final restored = widget.favoriteApps.where((a) => ids.contains(a.id)).toList();

      // Se houver diferenças (por exemplo usuário adicionou favoritos noutro lado),
      // _favoriteApps fica com a versão reconstruída (prioriza armazenamento local do utilizador).
      setState(() {
        _favoriteApps = restored;
        _loadingPrefs = false;
      });
    } catch (e) {
      // falha a ler - segue adiante com os dados recebidos
      setState(() => _loadingPrefs = false);
    }
  }

  Future<void> _saveFavoritesToPrefs(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, ids);
    } catch (e) {
      // fail silently
    }
  }

  // --------- UI helpers ----------
  List<AppModel> get _filteredApps {
    if (_searchQuery.isEmpty) return _favoriteApps;
    final q = _searchQuery.toLowerCase();
    return _favoriteApps.where((app) => app.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _removeFavorite(AppModel app) async {
    // Atualiza serviço (se existir). Não depende do retorno para UX.
    try {
      await _appService.toggleFavorite(app.id);
    } catch (_) {
      // ignore erros do serviço; mantemos persistência local para evitar bloqueio
    }

    // guarda snapshot para undo
    final removedIndex = _favoriteApps.indexWhere((a) => a.id == app.id);
    AppModel? removedApp;
    if (removedIndex >= 0) {
      removedApp = _favoriteApps.removeAt(removedIndex);
    }

    // atualiza prefs
    await _saveFavoritesToPrefs(_favoriteApps.map((a) => a.id).toList());

    if (!mounted) return;

    // Mostra snack / alerta de sucesso com undo
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${app.name} removido dos favoritos'),
        backgroundColor: const Color(0xFF1C1C1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Desfazer',
          textColor: const Color(0xFF007AFF),
          onPressed: () async {
            if (removedApp != null) {
              // desfaz localmente
              setState(() {
                _favoriteApps.insert(removedIndex >= 0 ? removedIndex : 0, removedApp!);
              });
              // salva
              await _saveFavoritesToPrefs(_favoriteApps.map((a) => a.id).toList());
              // tenta sincronizar com serviço
              try {
                await _appService.toggleFavorite(app.id);
              } catch (_) {}
            }
          },
        ),
      ),
    );

    setState(() {});
  }

  void _showRemoveDialog(AppModel app) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remover Favorito'),
        content: Text('Deseja remover "${app.name}" dos favoritos?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _removeFavorite(app);
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _clearAllFavorites() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Limpar Favoritos'),
        content: const Text('Deseja remover todos os apps dos favoritos?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              // chama toggleFavorite para cada app (se preferires podes chamar um endpoint em lote)
              for (var app in List<AppModel>.from(_favoriteApps)) {
                try {
                  await _appService.toggleFavorite(app.id);
                } catch (_) {}
              }
              setState(() {
                _favoriteApps.clear();
                _isEditMode = false;
              });
              await _saveFavoritesToPrefs([]);
            },
            child: const Text('Limpar Tudo'),
          ),
        ],
      ),
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    // enquanto prefs carrega, mostra loading simples
    if (_loadingPrefs) {
      return const CupertinoPageScaffold(
        backgroundColor: Color(0xFF000000),
        navigationBar: CupertinoNavigationBar(
          middle: Text('Favoritos', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF000000),
        ),
        child: Center(child: CupertinoActivityIndicator(radius: 16)),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF000000),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF2C2C2E), width: 0.5),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Color(0xFF007AFF)),
        ),
        middle: const Text(
          'Favoritos',
          style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 17, fontWeight: FontWeight.w600),
        ),
        trailing: _favoriteApps.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _isEditMode = !_isEditMode),
                child: Text(
                  _isEditMode ? 'Concluir' : 'Editar',
                  style: const TextStyle(color: Color(0xFF007AFF), fontSize: 17, fontWeight: FontWeight.w400),
                ),
              )
            : null,
      ),
      child: _favoriteApps.isEmpty ? _buildEmptyState() : SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        if (_favoriteApps.isNotEmpty) _buildSearchBar(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredApps.length} ${_filteredApps.length == 1 ? 'app' : 'apps'}',
                        style: const TextStyle(fontSize: 15, color: Color(0xFF8E8E93), fontWeight: FontWeight.w500),
                      ),
                      if (_isEditMode && _favoriteApps.isNotEmpty)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _clearAllFavorites,
                          child: const Text(
                            'Limpar tudo',
                            style: TextStyle(color: Color(0xFFFF3B30), fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_filteredApps.isEmpty && _searchQuery.isNotEmpty)
                SliverFillRemaining(child: _buildNoResultsState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final app = _filteredApps[index];
                        return _buildFavoriteAppItem(app);
                      },
                      childCount: _filteredApps.length,
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 36,
      decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(CupertinoIcons.search, color: Color(0xFF8E8E93), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: CupertinoTextField(
              controller: _searchController,
              placeholder: 'Buscar',
              placeholderStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
              style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 15),
              decoration: null,
              autocorrect: false,
              enableSuggestions: false,
              cursorColor: const Color(0xFF007AFF),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 20,
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(CupertinoIcons.clear_circled_solid, color: Color(0xFF8E8E93), size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(60)),
              child: const Icon(CupertinoIcons.heart_fill, size: 60, color: Color(0xFFFF3B30)),
            ),
            const SizedBox(height: 32),
            const Text(
              'Nenhum favorito',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Adicione apps aos favoritos tocando no ícone de coração para acesso rápido',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.search, size: 64, color: Color(0xFF8E8E93)),
            const SizedBox(height: 24),
            const Text(
              'Nenhum resultado',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Nenhum app encontrado para "${_searchQuery}"',
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteAppItem(AppModel app) {
    return GestureDetector(
      onTap: _isEditMode ? null : () => widget.onAppTap(app),
      onLongPress: () {
        if (!_isEditMode) {
          setState(() => _isEditMode = true);
        }
      },
      child: Stack(
        children: [
          Column(
            children: [
              AnimatedScale(
                scale: _isEditMode ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      app.iconUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(CupertinoIcons.app_fill, color: Color(0xFF8E8E93), size: 32),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                app.name,
                style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12, fontWeight: FontWeight.w500),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          if (_isEditMode)
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: () => _showRemoveDialog(app),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF000000), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(CupertinoIcons.minus, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
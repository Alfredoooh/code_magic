import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/app_model.dart';
import '../../models/feature_model.dart';
import '../../models/product_model.dart';
import '../../services/app_service.dart';
import '../../services/feature_service.dart';
import '../../services/commerce_service.dart';
import 'app_detail_screen.dart';
import 'feature_detail_screen.dart';
import 'product_detail_screen.dart';

class UniversalSearchScreen extends StatefulWidget {
  final int initialTab;

  const UniversalSearchScreen({
    Key? key,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<UniversalSearchScreen> createState() => _UniversalSearchScreenState();
}

class _UniversalSearchScreenState extends State<UniversalSearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late TabController _tabController;
  
  final AppService _appService = AppService();
  final FeatureService _featureService = FeatureService();
  final CommerceService _commerceService = CommerceService();

  List<AppModel> _allApps = [];
  List<FeatureModel> _allFeatures = [];
  List<ProductModel> _allProducts = [];

  List<AppModel> _filteredApps = [];
  List<FeatureModel> _filteredFeatures = [];
  List<ProductModel> _filteredProducts = [];

  String _searchQuery = '';
  bool _isLoading = true;

  // Filtros para produtos
  String _selectedCategory = 'Todos';
  String _selectedBrand = 'Todas';
  double _minPrice = 0;
  double _maxPrice = 10000;
  String _sortBy = 'Relevância';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _focusNode.requestFocus();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    final apps = await _appService.fetchAllApps();
    final features = await _featureService.fetchAllFeatures();
    final products = await _commerceService.fetchAllProducts();

    if (mounted) {
      setState(() {
        _allApps = apps;
        _allFeatures = features;
        _allProducts = products;
        _isLoading = false;
      });
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
      
      if (query.isEmpty) {
        _filteredApps = [];
        _filteredFeatures = [];
        _filteredProducts = [];
      } else {
        _filteredApps = _appService.searchApps(_allApps, query);
        _filteredFeatures = _featureService.searchFeatures(_allFeatures, query);
        _filteredProducts = _commerceService.searchProducts(_allProducts, query);
        
        // Aplica filtros adicionais aos produtos
        _applyProductFilters();
      }
    });
  }

  void _applyProductFilters() {
    List<ProductModel> filtered = _filteredProducts;

    // Filtro por categoria
    if (_selectedCategory != 'Todos') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    // Filtro por marca
    if (_selectedBrand != 'Todas') {
      filtered = filtered.where((p) => p.brand == _selectedBrand).toList();
    }

    // Filtro por preço
    filtered = filtered.where((p) => p.price >= _minPrice && p.price <= _maxPrice).toList();

    // Ordenação
    if (_sortBy == 'Preço: Menor') {
      filtered.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Preço: Maior') {
      filtered.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Avaliação') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _showFilters() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFF2C2C2E),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'Todos';
                          _selectedBrand = 'Todas';
                          _minPrice = 0;
                          _maxPrice = 10000;
                          _sortBy = 'Relevância';
                        });
                        _performSearch(_searchQuery);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Limpar',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Text(
                      'Filtros',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        _performSearch(_searchQuery);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Aplicar',
                        style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildFilterSection(
                      'Ordenar por',
                      ['Relevância', 'Preço: Menor', 'Preço: Maior', 'Avaliação'],
                      _sortBy,
                      (value) => setState(() => _sortBy = value),
                    ),
                    const SizedBox(height: 24),
                    _buildFilterSection(
                      'Categoria',
                      _commerceService.getCategories(_allProducts),
                      _selectedCategory,
                      (value) => setState(() => _selectedCategory = value),
                    ),
                    const SizedBox(height: 24),
                    _buildFilterSection(
                      'Marca',
                      _commerceService.getBrands(_allProducts),
                      _selectedBrand,
                      (value) => setState(() => _selectedBrand = value),
                    ),
                    const SizedBox(height: 24),
                    _buildPriceRangeFilter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String selected, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selected;
            return GestureDetector(
              onTap: () => onSelect(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF007AFF) : const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFFFFFFF) : const Color(0xFF8E8E93),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Faixa de Preço',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              '€${_minPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 15,
              ),
            ),
            Expanded(
              child: RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: 10000,
                divisions: 100,
                activeColor: const Color(0xFF007AFF),
                inactiveColor: const Color(0xFF2C2C2E),
                onChanged: (RangeValues values) {
                  setState(() {
                    _minPrice = values.start;
                    _maxPrice = values.end;
                  });
                },
              ),
            ),
            Text(
              '€${_maxPrice.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        radius: 20,
                        color: Color(0xFF007AFF),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildAppsResults(),
                        _buildFeaturesResults(),
                        _buildProductsResults(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Pesquisar...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    CupertinoIcons.search,
                    color: Color(0xFF8E8E93),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_tabController.index == 2)
                              IconButton(
                                icon: const Icon(
                                  CupertinoIcons.slider_horizontal_3,
                                  size: 18,
                                ),
                                color: const Color(0xFF007AFF),
                                onPressed: _showFilters,
                              ),
                            IconButton(
                              icon: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                size: 18,
                              ),
                              color: const Color(0xFF8E8E93),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            ),
                          ],
                        )
                      : _tabController.index == 2
                          ? IconButton(
                              icon: const Icon(
                                CupertinoIcons.slider_horizontal_3,
                                size: 18,
                              ),
                              color: const Color(0xFF8E8E93),
                              onPressed: _showFilters,
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: _performSearch,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF007AFF),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(22),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFFFFFFFF),
        unselectedLabelColor: const Color(0xFF8E8E93),
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        tabs: [
          Tab(text: 'Apps (${_filteredApps.length})'),
          Tab(text: 'Funcionalidades (${_filteredFeatures.length})'),
          Tab(text: 'Produtos (${_filteredProducts.length})'),
        ],
      ),
    );
  }

  Widget _buildAppsResults() {
    if (_searchQuery.isEmpty) {
      return _buildEmptySearch('apps');
    }

    if (_filteredApps.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredApps.length,
      itemBuilder: (context, index) {
        final app = _filteredApps[index];
        return _buildAppCard(app);
      },
    );
  }

  Widget _buildFeaturesResults() {
    if (_searchQuery.isEmpty) {
      return _buildEmptySearch('funcionalidades');
    }

    if (_filteredFeatures.isEmpty) {
      return _buildNoResults();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFeatures.length,
      itemBuilder: (context, index) {
        final feature = _filteredFeatures[index];
        return _buildFeatureCard(feature);
      },
    );
  }

  Widget _buildProductsResults() {
    if (_searchQuery.isEmpty) {
      return _buildEmptySearch('produtos');
    }

    if (_filteredProducts.isEmpty) {
      return _buildNoResults();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildAppCard(AppModel app) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => AppDetailScreen(app: app),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2C2C2E),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  app.iconUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF2C2C2E),
                    child: const Icon(
                      CupertinoIcons.app,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    app.description,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.star_fill,
                        color: Color(0xFFFFCC00),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        app.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFF8E8E93),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(FeatureModel feature) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => FeatureDetailScreen(feature: feature),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2C2C2E),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  feature.iconUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF2C2C2E),
                    child: const Icon(
                      CupertinoIcons.star_fill,
                      color: Color(0xFFFF9500),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.name,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    feature.description,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.star_fill,
                        color: Color(0xFFFFCC00),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        feature.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color(0xFF8E8E93),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  color: const Color(0xFF2C2C2E),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const Icon(
                            CupertinoIcons.bag,
                            color: Color(0xFF8E8E93),
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    if (product.discount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${product.discount}%',
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (product.discount > 0) ...[
                        Text(
                          '€${product.originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '€${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearch(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.search,
            size: 64,
            color: const Color(0xFF8E8E93),
          ),
          const SizedBox(height: 16),
          Text(
            'Pesquisar $type',
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 64,
            color: Color(0xFF8E8E93),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum resultado',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente pesquisar "$_searchQuery"',
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
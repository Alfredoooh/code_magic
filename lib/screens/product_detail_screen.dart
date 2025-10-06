import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/product_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  String? _selectedColor;
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    if (widget.product.colors.isNotEmpty) {
      _selectedColor = widget.product.colors.first;
    }
    if (widget.product.sizes.isNotEmpty) {
      _selectedSize = widget.product.sizes.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              CupertinoSliverNavigationBar(
                backgroundColor: const Color(0xFF000000).withOpacity(0.9),
                border: null,
                leading: CupertinoNavigationBarBackButton(
                  color: const Color(0xFF007AFF),
                  onPressed: () => Navigator.pop(context),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      child: const Icon(
                        CupertinoIcons.share,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {},
                      child: const Icon(
                        CupertinoIcons.heart,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProductHeader(),
                          const SizedBox(height: 20),
                          _buildPriceSection(),
                          const SizedBox(height: 24),
                          if (widget.product.colors.isNotEmpty) ...[
                            _buildColorSelector(),
                            const SizedBox(height: 24),
                          ],
                          if (widget.product.sizes.isNotEmpty) ...[
                            _buildSizeSelector(),
                            const SizedBox(height: 24),
                          ],
                          _buildDescription(),
                          const SizedBox(height: 24),
                          if (widget.product.features.isNotEmpty) ...[
                            _buildFeatures(),
                            const SizedBox(height: 24),
                          ],
                          if (widget.product.specifications.isNotEmpty) ...[
                            _buildSpecifications(),
                            const SizedBox(height: 24),
                          ],
                          _buildReviews(),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = widget.product.images.isNotEmpty 
        ? widget.product.images 
        : [widget.product.imageUrl];

    return Column(
      children: [
        Container(
          height: 400,
          color: const Color(0xFF1C1C1E),
          child: PageView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() => _selectedImageIndex = index);
            },
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  CupertinoIcons.bag,
                  color: Color(0xFF8E8E93),
                  size: 80,
                ),
              );
            },
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedImageIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedImageIndex = index);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF007AFF) 
                            : const Color(0xFF2C2C2E),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.product.brand,
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.product.inStock 
                    ? const Color(0xFF34C759).withOpacity(0.2)
                    : const Color(0xFFFF3B30).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.product.inStock ? 'Em Stock' : 'Esgotado',
                style: TextStyle(
                  color: widget.product.inStock 
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF3B30),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.product.name,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < widget.product.rating.floor()
                      ? CupertinoIcons.star_fill
                      : CupertinoIcons.star,
                  color: const Color(0xFFFFCC00),
                  size: 18,
                );
              }),
            ),
            const SizedBox(width: 8),
            Text(
              widget.product.rating.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${widget.product.reviews} avaliações)',
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF007AFF).withOpacity(0.2),
            const Color(0xFF1C1C1E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.product.discount > 0) ...[
                Text(
                  '€${widget.product.originalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                '€${widget.product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (widget.product.discount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '-${widget.product.discount}%',
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cor',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.product.colors.map((color) {
            final isSelected = color == _selectedColor;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF007AFF) 
                      : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF007AFF) 
                        : const Color(0xFF2C2C2E),
                    width: 2,
                  ),
                ),
                child: Text(
                  color,
                  style: TextStyle(
                    color: isSelected 
                        ? const Color(0xFFFFFFFF) 
                        : const Color(0xFF8E8E93),
                    fontSize: 15,
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

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tamanho',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.product.sizes.map((size) {
            final isSelected = size == _selectedSize;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedSize = size);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFF007AFF) 
                      : const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFF007AFF) 
                        : const Color(0xFF2C2C2E),
                    width: 2,
                  ),
                ),
                child: Text(
                  size,
                  style: TextStyle(
                    color: isSelected 
                        ? const Color(0xFFFFFFFF) 
                        : const Color(0xFF8E8E93),
                    fontSize: 15,
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

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descrição',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.product.description,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Características',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: widget.product.features.map((feature) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: Color(0xFF34C759),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Especificações',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: widget.product.specifications.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReviews() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Avaliações',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {},
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    widget.product.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return const Icon(
                              CupertinoIcons.star_fill,
                              color: Color(0xFFFFCC00),
                              size: 20,
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Baseado em ${widget.product.reviews} avaliações',
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF2C2C2E),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {},
              child: const Icon(
                CupertinoIcons.cart,
                color: Color(0xFFFFFFFF),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: widget.product.inStock 
                  ? const Color(0xFF007AFF)
                  : const Color(0xFF8E8E93),
              borderRadius: BorderRadius.circular(12),
              onPressed: widget.product.inStock ? () {} : null,
              child: Text(
                widget.product.inStock ? 'Comprar Agora' : 'Esgotado',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
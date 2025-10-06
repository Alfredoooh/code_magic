import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../models/feature_model.dart';

class FeatureDetailScreen extends StatelessWidget {
  final FeatureModel feature;

  const FeatureDetailScreen({
    Key? key,
    required this.feature,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: const Color(0xFF000000).withOpacity(0.9),
            border: null,
            largeTitle: Text(
              feature.name,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
              ),
            ),
            leading: CupertinoNavigationBarBackButton(
              color: const Color(0xFF007AFF),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildInfoCards(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  if (feature.screenshots.isNotEmpty) _buildScreenshots(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFF9500).withOpacity(0.3),
                const Color(0xFF1C1C1E),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9500).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
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
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feature.name,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feature.category,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.star_fill,
                    color: Color(0xFFFFCC00),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    feature.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            CupertinoIcons.arrow_down_circle,
            '${(feature.downloads / 1000).toStringAsFixed(1)}K',
            'Downloads',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            CupertinoIcons.cube_box,
            feature.version,
            'Versão',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            CupertinoIcons.person,
            feature.developer,
            'Desenvolvedor',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFFFF9500),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sobre',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 20,
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
            feature.description,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshots() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Screenshots',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 400,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: feature.screenshots.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  feature.screenshots[index],
                  width: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      CupertinoIcons.photo,
                      color: Color(0xFF8E8E93),
                      size: 48,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
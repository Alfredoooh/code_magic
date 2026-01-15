import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final Color surfaceColor;
  final Color borderColor;

  const SkeletonLoader({
    Key? key,
    required this.surfaceColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(
            child: Container(
              width: 150,
              height: 12,
              decoration: BoxDecoration(
                color: widget.borderColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildShimmer(
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: widget.borderColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      onEnd: () {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) setState(() {});
        });
      },
      child: child,
    );
  }
}
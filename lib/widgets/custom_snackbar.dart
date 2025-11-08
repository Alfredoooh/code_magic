// lib/widgets/custom_snackbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'custom_icons.dart';

enum SnackbarType { info, success, error, warning }

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    bool isDark = false,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _SnackbarWidget(
        message: message,
        type: type,
        isDark: isDark,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    bool isDark = false,
  }) {
    show(context, message: message, type: SnackbarType.info, isDark: isDark);
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    bool isDark = false,
  }) {
    show(context, message: message, type: SnackbarType.success, isDark: isDark);
  }

  static void showError(
    BuildContext context, {
    required String message,
    bool isDark = false,
  }) {
    show(context, message: message, type: SnackbarType.error, isDark: isDark);
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    bool isDark = false,
  }) {
    show(context, message: message, type: SnackbarType.warning, isDark: isDark);
  }
}

class _SnackbarWidget extends StatefulWidget {
  final String message;
  final SnackbarType type;
  final bool isDark;
  final VoidCallback onDismiss;

  const _SnackbarWidget({
    required this.message,
    required this.type,
    required this.isDark,
    required this.onDismiss,
  });

  @override
  State<_SnackbarWidget> createState() => _SnackbarWidgetState();
}

class _SnackbarWidgetState extends State<_SnackbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case SnackbarType.info:
        return widget.isDark
            ? const Color(0xFF1A2332)
            : const Color(0xFFE3F2FD);
      case SnackbarType.success:
        return widget.isDark
            ? const Color(0xFF1B2E1F)
            : const Color(0xFFE8F5E9);
      case SnackbarType.error:
        return widget.isDark
            ? const Color(0xFF2E1C1C)
            : const Color(0xFFFFEBEE);
      case SnackbarType.warning:
        return widget.isDark
            ? const Color(0xFF2D2416)
            : const Color(0xFFFFF8E1);
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case SnackbarType.info:
        return const Color(0xFF2196F3);
      case SnackbarType.success:
        return const Color(0xFF4CAF50);
      case SnackbarType.error:
        return const Color(0xFFF44336);
      case SnackbarType.warning:
        return const Color(0xFFFFA000);
    }
  }

  String _getIcon() {
    switch (widget.type) {
      case SnackbarType.info:
        return CustomIcons.info;
      case SnackbarType.success:
        return CustomIcons.checkCircle;
      case SnackbarType.error:
        return CustomIcons.close;
      case SnackbarType.warning:
        return CustomIcons.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark
        ? const Color(0xFFE4E6EB)
        : const Color(0xFF050505);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getIconColor().withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.string(
                        _getIcon(),
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          _getIconColor(),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _controller.reverse().then((_) => widget.onDismiss());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
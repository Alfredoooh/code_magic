// lib/screens/messages_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Row(
          children: [
            SvgIcon(
              svgString: CustomIcons.inbox,
              color: textColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Inbox',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(
              svgString: CustomIcons.envelope,
              color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFDADADA),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma mensagem',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
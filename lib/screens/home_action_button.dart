// lib/screens/home_action_button.dart
import 'package:flutter/material.dart';
import '../widgets/app_ui_components.dart';
import 'create_post_screen.dart';
import 'more_options_screen.dart' hide WalletCard;
import 'plans_screen.dart';

class HomeActionButton extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final Future<bool> Function(String) onCheckToken;
  final bool isDark;

  const HomeActionButton({
    required this.userData,
    required this.onCheckToken,
    required this.isDark,
    Key? key,
  }) : super(key: key);

  void _showOptionsBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context,
      height: 350,
      child: Column(
        children: [
          SizedBox(height: 20),
          _buildModalOption(
            context,
            icon: Icons.arrow_upward_rounded,
            label: 'Enviar',
            isDark: isDark,
            onPressed: () => Navigator.pop(context),
          ),
          _buildModalOption(
            context,
            icon: Icons.add_circle,
            label: 'Criar Publicação',
            isDark: isDark,
            onPressed: () {
              Navigator.pop(context);
              _handleCreatePost(context);
            },
          ),
          _buildModalOption(
            context,
            icon: Icons.arrow_downward_rounded,
            label: 'Receber',
            isDark: isDark,
            onPressed: () => Navigator.pop(context),
          ),
          _buildModalOption(
            context,
            icon: Icons.more_horiz,
            label: 'Mais Opções',
            isDark: isDark,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MoreOptionsScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModalOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreatePost(BuildContext context) async {
    final isPro = userData?['pro'] == true;

    if (!isPro) {
      AppDialogs.showConfirmation(
        context,
        'Recursos PRO',
        'Apenas usuários PRO podem criar publicações. Atualize sua conta para desbloquear este recurso.',
        onConfirm: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlansScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        confirmText: 'Atualizar para PRO',
        cancelText: 'Entendi',
      );
      return;
    }

    final canProceed = await onCheckToken('create_post');
    if (!canProceed) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(
          userData: userData ?? {},
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => _showOptionsBottomSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.blue.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(
          'Começar',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
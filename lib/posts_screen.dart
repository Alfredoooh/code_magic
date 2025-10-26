// posts_screen.dart
import 'package:flutter/material.dart';
import 'styles.dart';

class PostsScreen extends StatelessWidget {
  final String token;

  const PostsScreen({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: FadeInWidget(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone animado
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.article_rounded,
                    size: 80,
                    color: context.colors.primary,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Título
                Text(
                  'Publicações',
                  style: context.textStyles.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.md),
                
                // Descrição
                Text(
                  'Em breve você poderá ver publicações\ne atualizações da comunidade',
                  textAlign: TextAlign.center,
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Features vindas
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: context.colors.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        context,
                        Icons.people_rounded,
                        'Comunidade',
                        'Conecte-se com outros traders',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFeatureItem(
                        context,
                        Icons.school_rounded,
                        'Aprenda',
                        'Tutoriais e estratégias',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFeatureItem(
                        context,
                        Icons.notifications_active_rounded,
                        'Notificações',
                        'Fique atualizado com as novidades',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Botão de notificação
                OutlinedButton.icon(
                  onPressed: () {
                    AppHaptics.light();
                    AppSnackbar.info(
                      context,
                      'Notificaremos você quando essa feature estiver disponível!',
                    );
                  },
                  icon: const Icon(Icons.notifications_none_rounded),
                  label: const Text('Me Notifique'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            color: context.colors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                description,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
// posts_screen.dart - Material Design 3
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

class PostsScreen extends StatefulWidget {
  final String token;

  const PostsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _notifyEnabled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: PrimaryAppBar(
        title: 'Community Posts',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildHeroIcon(context),
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildTitle(context),
                  const SizedBox(height: AppSpacing.md),
                  _buildDescription(context),
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildFeaturesCard(context),
                  const SizedBox(height: AppSpacing.xxxl),
                  _buildNotificationButton(context),
                  const Spacer(),
                  _buildFooterText(context),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroIcon(BuildContext context) {
    return FadeInWidget(
      duration: AppMotion.long,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.article_rounded,
            size: 70,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 200),
      child: Text(
        'Coming Soon',
        style: context.textStyles.displaySmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: context.colors.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 300),
      child: Text(
        'Connect with the trading community.\nShare insights, strategies, and learn together.',
        textAlign: TextAlign.center,
        style: context.textStyles.bodyLarge?.copyWith(
          color: context.colors.onSurfaceVariant,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFeaturesCard(BuildContext context) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 400),
      child: GlassCard(
        blur: 15,
        opacity: 0.05,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: context.colors.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppBadge(
                      text: 'Upcoming',
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'What\'s Coming',
                        style: context.textStyles.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const LabeledDivider(label: 'Features'),
                const SizedBox(height: AppSpacing.lg),
                _buildFeatureItem(
                  context,
                  Icons.people_rounded,
                  'Community Hub',
                  'Connect with traders worldwide',
                  AppColors.primary,
                  0,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildFeatureItem(
                  context,
                  Icons.school_rounded,
                  'Learning Center',
                  'Expert tutorials and strategies',
                  AppColors.success,
                  1,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildFeatureItem(
                  context,
                  Icons.trending_up_rounded,
                  'Market Insights',
                  'Real-time analysis and signals',
                  AppColors.tertiary,
                  2,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildFeatureItem(
                  context,
                  Icons.notifications_active_rounded,
                  'Smart Alerts',
                  'Stay updated with push notifications',
                  AppColors.warning,
                  3,
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
    Color color,
    int index,
  ) {
    return StaggeredListItem(
      index: index,
      delay: const Duration(milliseconds: 100),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.onSurfaceVariant.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 600),
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.standardEasing,
        child: Column(
          children: [
            PrimaryButton(
              text: _notifyEnabled ? 'Notifications Active' : 'Notify Me',
              icon: _notifyEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              onPressed: () {
                AppHaptics.selection();
                setState(() {
                  _notifyEnabled = !_notifyEnabled;
                });
                
                if (_notifyEnabled) {
                  AppSnackbar.success(
                    context,
                    'You\'ll be notified when this feature launches! 🎉',
                  );
                } else {
                  AppSnackbar.info(
                    context,
                    'Notification disabled',
                  );
                }
              },
              expanded: false,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              text: 'Learn More',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                AppHaptics.light();
                _showInfoDialog(context);
              },
              expanded: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterText(BuildContext context) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 700),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'In Development',
            style: context.textStyles.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    AppDialog.show(
      context: context,
      title: 'Community Posts',
      icon: Icons.article_rounded,
      iconColor: AppColors.primary,
      content: 'We\'re building an amazing community feature where you can:\n\n'
          '• Share trading strategies\n'
          '• Discuss market trends\n'
          '• Learn from experts\n'
          '• Get real-time updates\n\n'
          'Enable notifications to be the first to know when it launches!',
      actions: [
        TertiaryButton(
          text: 'Maybe Later',
          onPressed: () => Navigator.pop(context),
        ),
        PrimaryButton(
          text: 'Notify Me',
          icon: Icons.notifications_active_rounded,
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              _notifyEnabled = true;
            });
            AppSnackbar.success(
              context,
              'Notification enabled! 🔔',
            );
          },
        ),
      ],
    );
  }
}

// Alternative: Grid-based feature showcase
class PostsScreenGrid extends StatelessWidget {
  final String token;

  const PostsScreenGrid({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: PrimaryAppBar(title: 'Community'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            EmptyState(
              icon: Icons.article_rounded,
              title: 'Posts Coming Soon',
              subtitle: 'Connect with traders worldwide',
              actionText: 'Notify Me',
              onAction: () {
                AppSnackbar.success(
                  context,
                  'You\'ll be notified! 🎉',
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              children: [
                _buildFeatureCard(
                  context,
                  Icons.people_rounded,
                  'Community',
                  AppColors.primary,
                ),
                _buildFeatureCard(
                  context,
                  Icons.school_rounded,
                  'Learn',
                  AppColors.success,
                ),
                _buildFeatureCard(
                  context,
                  Icons.trending_up_rounded,
                  'Insights',
                  AppColors.tertiary,
                ),
                _buildFeatureCard(
                  context,
                  Icons.notifications_active_rounded,
                  'Alerts',
                  AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
  ) {
    return AnimatedCard(
      onTap: () {
        AppHaptics.light();
        AppSnackbar.info(context, '$title coming soon!');
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppBadge(
            text: 'Soon',
            color: color,
            outlined: true,
          ),
        ],
      ),
    );
  }
}
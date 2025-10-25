// dashboard_screen.dart
import 'package:flutter/material.dart';
import 'styles.dart'; // Import do seu arquivo de estilos

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              AppHaptics.light();
              AppSnackbar.info(context, 'Você não tem notificações');
            },
          ),
          IconButton(
            icon: Icon(
              context.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              AppHaptics.medium();
              AppTheme.toggleTheme();
              setState(() {});
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Carregando dados...',
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _isLoading = true);
            await Future.delayed(AppMotion.long);
            setState(() => _isLoading = false);
            if (mounted) {
              AppSnackbar.success(context, 'Dados atualizados');
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Seção de boas-vindas
              FadeInWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, Usuário!',
                      style: context.textStyles.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Bem-vindo de volta',
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Cards de estatísticas
              FadeInWidget(
                delay: const Duration(milliseconds: 100),
                child: Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        label: 'Receita',
                        value: 'R\$ 12.5K',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                        subtitle: '+12% este mês',
                        onTap: () {
                          AppHaptics.selection();
                          AppSnackbar.info(context, 'Receita mensal');
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: StatsCard(
                        label: 'Despesas',
                        value: 'R\$ 8.2K',
                        icon: Icons.trending_down_rounded,
                        color: AppColors.error,
                        subtitle: '-5% este mês',
                        onTap: () {
                          AppHaptics.selection();
                          AppSnackbar.warning(context, 'Despesas mensais');
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              FadeInWidget(
                delay: const Duration(milliseconds: 200),
                child: StatsCard(
                  label: 'Saldo Total',
                  value: 'R\$ 24.3K',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.primary,
                  subtitle: 'Atualizado agora',
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Seção de ações rápidas
              FadeInWidget(
                delay: const Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ações Rápidas',
                      style: context.textStyles.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedPrimaryButton(
                            text: 'Adicionar',
                            icon: Icons.add_rounded,
                            onPressed: () {
                              AppHaptics.medium();
                              _showAddBottomSheet(context);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              AppHaptics.light();
                              AppSnackbar.info(context, 'Relatórios em breve');
                            },
                            icon: const Icon(Icons.bar_chart_rounded),
                            label: const Text('Relatório'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Seção de informações
              FadeInWidget(
                delay: const Duration(milliseconds: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações',
                      style: context.textStyles.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    InfoCard(
                      icon: Icons.credit_card_rounded,
                      title: 'Cartões',
                      subtitle: '3 cartões cadastrados',
                      color: AppColors.secondary,
                      onTap: () {
                        AppHaptics.selection();
                        AppSnackbar.info(context, 'Gerenciar cartões');
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InfoCard(
                      icon: Icons.account_balance_rounded,
                      title: 'Contas Bancárias',
                      subtitle: '2 contas conectadas',
                      color: AppColors.tertiary,
                      onTap: () {
                        AppHaptics.selection();
                        AppSnackbar.info(context, 'Gerenciar contas');
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InfoCard(
                      icon: Icons.savings_rounded,
                      title: 'Investimentos',
                      subtitle: 'R\$ 15.7K investidos',
                      color: AppColors.info,
                      onTap: () {
                        AppHaptics.selection();
                        AppSnackbar.info(context, 'Ver investimentos');
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
              
              // Seção de transações recentes
              FadeInWidget(
                delay: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transações Recentes',
                          style: context.textStyles.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            AppHaptics.light();
                            AppSnackbar.info(context, 'Ver todas');
                          },
                          child: const Text('Ver todas'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      child: Column(
                        children: [
                          StaggeredListItem(
                            index: 0,
                            child: TransactionListItem(
                              title: 'Salário',
                              subtitle: 'Recebido hoje',
                              amount: 5000.00,
                              icon: Icons.arrow_downward_rounded,
                              onTap: () {
                                AppHaptics.selection();
                                AppSnackbar.info(context, 'Detalhes da transação');
                              },
                            ),
                          ),
                          Divider(height: 1, color: context.colors.outlineVariant),
                          StaggeredListItem(
                            index: 1,
                            child: TransactionListItem(
                              title: 'Supermercado',
                              subtitle: 'Ontem às 14:30',
                              amount: -234.50,
                              icon: Icons.shopping_cart_rounded,
                              onTap: () {
                                AppHaptics.selection();
                                AppSnackbar.info(context, 'Detalhes da transação');
                              },
                            ),
                          ),
                          Divider(height: 1, color: context.colors.outlineVariant),
                          StaggeredListItem(
                            index: 2,
                            child: TransactionListItem(
                              title: 'Netflix',
                              subtitle: '25 Out 2025',
                              amount: -49.90,
                              icon: Icons.play_circle_outline_rounded,
                              onTap: () {
                                AppHaptics.selection();
                                AppSnackbar.info(context, 'Detalhes da transação');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppSpacing.massive),
            ],
          ),
        ),
      ),
      floatingActionButton: FadeInWidget(
        delay: const Duration(milliseconds: 600),
        child: FloatingActionButton.extended(
          onPressed: () {
            AppHaptics.heavy();
            _showAddBottomSheet(context);
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nova Transação'),
        ),
      ),
    );
  }

  void _showAddBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nova Transação',
                    style: context.textStyles.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Ex: Almoço no restaurante',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  hintText: 'R\$ 0,00',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AnimatedPrimaryButton(
                  text: 'Adicionar Transação',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    AppHaptics.heavy();
                    Navigator.pop(context);
                    AppSnackbar.success(context, 'Transação adicionada com sucesso!');
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
// lib/bot_create_screen.dart
// Tela para criar novos bots personalizados
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'bot_engine.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';
import 'theme/app_widgets.dart';

class CreateBotScreen extends StatefulWidget {
  final WebSocketChannel channel;
  final Function(TradingBot) onBotCreated;

  const CreateBotScreen({
    Key? key,
    required this.channel,
    required this.onBotCreated,
  }) : super(key: key);

  @override
  State<CreateBotScreen> createState() => _CreateBotScreenState();
}

class _CreateBotScreenState extends State<CreateBotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _initialStake = 10.0;
  BotStrategy _selectedStrategy = BotStrategy.martingale;
  String _selectedMarket = 'R_100';
  String _contractType = 'CALL';
  RecoveryMode _recoveryMode = RecoveryMode.moderate;

  final _marketOptions = [
    'R_100',
    'R_50',
    'R_25',
    'R_75',
    'BOOM500',
    'BOOM1000',
    'CRASH500',
    'CRASH1000',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: SecondaryAppBar(
        title: 'Criar Bot Personalizado',
        onBack: () {
          AppHaptics.light();
          Navigator.pop(context);
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              FadeInWidget(
                child: _buildSectionHeader(
                  icon: Icons.settings_rounded,
                  title: 'Configuração Básica',
                  subtitle: 'Defina o nome e descrição do seu bot',
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Nome do Bot
              FadeInWidget(
                delay: Duration(milliseconds: 100),
                child: AppTextField(
                  controller: _nameController,
                  label: 'Nome do Bot',
                  hint: 'Ex: Bot Agressivo',
                  prefix: Icon(Icons.smart_toy_rounded),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Por favor, insira um nome';
                    }
                    return null;
                  },
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Descrição
              FadeInWidget(
                delay: Duration(milliseconds: 150),
                child: AppTextField(
                  controller: _descriptionController,
                  label: 'Descrição (opcional)',
                  hint: 'Descreva a estratégia do seu bot...',
                  prefix: Icon(Icons.description_rounded),
                  maxLines: 3,
                ),
              ),

              SizedBox(height: AppSpacing.xxxl),

              // Stake Section
              FadeInWidget(
                delay: Duration(milliseconds: 200),
                child: _buildSectionHeader(
                  icon: Icons.attach_money_rounded,
                  title: 'Investimento',
                  subtitle: 'Configure o valor inicial das operações',
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              FadeInWidget(
                delay: Duration(milliseconds: 250),
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.light();
                    _openStakeModal();
                  },
                  child: AnimatedCard(
                    onTap: _openStakeModal,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.success,
                              size: 28,
                            ),
                          ),
                          SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stake Inicial',
                                  style: context.textStyles.bodyMedium?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.xxs),
                                Text(
                                  '\$${_initialStake.toStringAsFixed(2)}',
                                  style: context.textStyles.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit_rounded,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.xxxl),

              // Strategy Section
              FadeInWidget(
                delay: Duration(milliseconds: 300),
                child: _buildSectionHeader(
                  icon: Icons.psychology_rounded,
                  title: 'Estratégia',
                  subtitle: 'Escolha o método de progressão',
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              FadeInWidget(
                delay: Duration(milliseconds: 350),
                child: _buildStrategySelector(),
              ),

              SizedBox(height: AppSpacing.xxxl),

              // Market Section
              FadeInWidget(
                delay: Duration(milliseconds: 400),
                child: _buildSectionHeader(
                  icon: Icons.show_chart_rounded,
                  title: 'Mercado',
                  subtitle: 'Selecione o ativo para negociação',
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              FadeInWidget(
                delay: Duration(milliseconds: 450),
                child: _buildMarketSelector(),
              ),

              SizedBox(height: AppSpacing.xxxl),

              // Recovery Mode Section
              FadeInWidget(
                delay: Duration(milliseconds: 500),
                child: _buildSectionHeader(
                  icon: Icons.restore_rounded,
                  title: 'Modo de Recuperação',
                  subtitle: 'Defina o nível de agressividade',
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              FadeInWidget(
                delay: Duration(milliseconds: 550),
                child: _buildRecoveryModeSelector(),
              ),

              SizedBox(height: AppSpacing.massive),

              // Create Button
              FadeInWidget(
                delay: Duration(milliseconds: 600),
                child: PrimaryButton(
                  text: 'Criar Bot',
                  icon: Icons.rocket_launch_rounded,
                  onPressed: _createBot,
                  expanded: true,
                ),
              ),

              SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            color: context.colors.onPrimaryContainer,
            size: 20,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
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

  Widget _buildStrategySelector() {
    return Column(
      children: BotStrategy.values.map((strategy) {
        final isSelected = _selectedStrategy == strategy;
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: AnimatedCard(
            onTap: () {
              AppHaptics.selection();
              setState(() => _selectedStrategy = strategy);
            },
            child: Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected 
                      ? context.colors.primary 
                      : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                children: [
                  Radio<BotStrategy>(
                    value: strategy,
                    groupValue: _selectedStrategy,
                    onChanged: (value) {
                      if (value != null) {
                        AppHaptics.selection();
                        setState(() => _selectedStrategy = value);
                      }
                    },
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStrategyName(strategy),
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? context.colors.primary 
                                : context.colors.onSurface,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xxs),
                        Text(
                          _getStrategyDescription(strategy),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: context.colors.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMarketSelector() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _marketOptions.map((market) {
        final isSelected = _selectedMarket == market;
        return FilterChip(
          selected: isSelected,
          label: Text(market),
          onSelected: (selected) {
            if (selected) {
              AppHaptics.selection();
              setState(() => _selectedMarket = market);
            }
          },
          selectedColor: context.colors.primaryContainer,
          checkmarkColor: context.colors.onPrimaryContainer,
        );
      }).toList(),
    );
  }

  Widget _buildRecoveryModeSelector() {
    return SegmentedButtonGroup<RecoveryMode>(
      values: RecoveryMode.values,
      selected: _recoveryMode,
      onChanged: (value) {
        AppHaptics.selection();
        setState(() => _recoveryMode = value);
      },
      labelBuilder: (mode) => _getRecoveryModeName(mode),
      iconBuilder: (mode) {
        switch (mode) {
          case RecoveryMode.aggressive:
            return Icons.rocket_rounded;
          case RecoveryMode.moderate:
            return Icons.speed_rounded;
          case RecoveryMode.conservative:
            return Icons.shield_rounded;
          default:
            return Icons.circle;
        }
      },
    );
  }

  void _openStakeModal() {
    AppModalBottomSheet.show(
      context: context,
      title: 'Definir Stake Inicial',
      child: _StakeInputWidget(
        initialValue: _initialStake,
        onConfirm: (value) {
          setState(() => _initialStake = value);
        },
      ),
    );
  }

  void _createBot() {
    if (!_formKey.currentState!.validate()) {
      AppHaptics.error();
      return;
    }

    AppHaptics.success();

    final bot = TradingBot(
      config: BotConfiguration(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? 'Bot personalizado'
            : _descriptionController.text.trim(),
        strategy: _selectedStrategy,
        initialStake: _initialStake,
        market: _selectedMarket,
        contractType: _contractType,
        recoveryMode: _recoveryMode,
      ),
      channel: widget.channel,
      onStatusUpdate: (_) {},
    );

    widget.onBotCreated(bot);
    Navigator.pop(context);

    AppSnackbar.success(
      context, 
      'Bot "${bot.config.name}" criado com sucesso!',
    );
  }

  String _getStrategyName(BotStrategy strategy) {
    switch (strategy) {
      case BotStrategy.martingale:
        return 'Martingale';
      case BotStrategy.antiMartingale:
        return 'Anti-Martingale';
      case BotStrategy.dalembert:
        return "D'Alembert";
      case BotStrategy.fibonacci:
        return 'Fibonacci';
      default:
        return strategy.toString().split('.').last;
    }
  }

  String _getStrategyDescription(BotStrategy strategy) {
    switch (strategy) {
      case BotStrategy.martingale:
        return 'Dobra o stake após cada perda. Alto risco, alta recompensa.';
      case BotStrategy.antiMartingale:
        return 'Dobra o stake após cada vitória. Minimiza perdas.';
      case BotStrategy.dalembert:
        return 'Aumenta gradualmente após perdas. Risco moderado.';
      case BotStrategy.fibonacci:
        return 'Segue a sequência de Fibonacci. Progressão equilibrada.';
      default:
        return 'Estratégia de trading';
    }
  }

  String _getRecoveryModeName(RecoveryMode mode) {
    switch (mode) {
      case RecoveryMode.aggressive:
        return 'Agressivo';
      case RecoveryMode.moderate:
        return 'Moderado';
      case RecoveryMode.conservative:
        return 'Conservador';
      default:
        return mode.toString().split('.').last;
    }
  }
}

// Widget separado para input de stake
class _StakeInputWidget extends StatefulWidget {
  final double initialValue;
  final Function(double) onConfirm;

  const _StakeInputWidget({
    required this.initialValue,
    required this.onConfirm,
  });

  @override
  State<_StakeInputWidget> createState() => _StakeInputWidgetState();
}

class _StakeInputWidgetState extends State<_StakeInputWidget> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue.toStringAsFixed(2),
    );
    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _controller,
          label: 'Valor em USD',
          hint: '10.00',
          prefix: Text(
            '\$ ',
            style: context.textStyles.headlineSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          validator: (value) {
            final amount = double.tryParse(value ?? '');
            if (amount == null || amount < 0.35) {
              return 'Valor mínimo: \$0.35';
            }
            return null;
          },
        ),

        SizedBox(height: AppSpacing.md),

        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: AppColors.info.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.info,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Valor mínimo: \$0.35',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: AppSpacing.xl),

        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                text: 'Cancelar',
                onPressed: () {
                  AppHaptics.light();
                  Navigator.pop(context);
                },
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(
                text: 'Confirmar',
                onPressed: () {
                  final value = double.tryParse(
                    _controller.text.replaceAll(',', '.'),
                  );
                  if (value != null && value >= 0.35) {
                    AppHaptics.success();
                    widget.onConfirm(value);
                    Navigator.pop(context);
                  } else {
                    AppHaptics.error();
                    AppSnackbar.error(
                      context,
                      'Insira um valor válido (mínimo \$0.35)',
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
// lib/bot_create_screen.dart
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';
import 'bot_engine.dart';

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
  
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stakeController = TextEditingController(text: '0.35');
  final _maxStakeController = TextEditingController(text: '10.00');
  final _targetProfitController = TextEditingController(text: '5.00');
  final _maxLossesController = TextEditingController(text: '7');

  // Selected values
  BotStrategy _selectedStrategy = BotStrategy.martingale;
  String _selectedMarket = 'R_100';
  String _selectedContractType = 'CALL';
  RecoveryMode _selectedRecoveryMode = RecoveryMode.intelligent;
  List<EntryCondition> _selectedConditions = [];
  bool _useRSI = false;

  final List<String> _markets = [
    'R_10', 'R_25', 'R_50', 'R_75', 'R_100',
    'BOOM500', 'BOOM1000', 'CRASH500', 'CRASH1000'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _stakeController.dispose();
    _maxStakeController.dispose();
    _targetProfitController.dispose();
    _maxLossesController.dispose();
    super.dispose();
  }

  void _createBot() {
    if (!_formKey.currentState!.validate()) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Preencha todos os campos corretamente');
      return;
    }

    final stake = double.tryParse(_stakeController.text.replaceAll(',', '.'));
    final maxStake = double.tryParse(_maxStakeController.text.replaceAll(',', '.'));
    final targetProfit = double.tryParse(_targetProfitController.text.replaceAll(',', '.'));
    final maxLosses = int.tryParse(_maxLossesController.text);

    if (stake == null || stake < 0.35) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Stake mínimo: \$0.35');
      return;
    }

    if (maxStake == null || maxStake < stake) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Max Stake deve ser maior que o Stake inicial');
      return;
    }

    if (targetProfit == null || targetProfit <= 0) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Target Profit deve ser maior que 0');
      return;
    }

    if (maxLosses == null || maxLosses < 1) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Max Losses deve ser pelo menos 1');
      return;
    }

    final config = BotConfiguration(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      strategy: _selectedStrategy,
      initialStake: stake,
      maxStake: maxStake,
      targetProfit: targetProfit,
      market: _selectedMarket,
      contractType: _selectedContractType,
      recoveryMode: _selectedRecoveryMode,
      entryConditions: _selectedConditions.isEmpty 
          ? [EntryCondition.immediate] 
          : _selectedConditions,
      maxConsecutiveLosses: maxLosses,
      useRSI: _useRSI,
    );

    final bot = TradingBot(
      config: config,
      channel: widget.channel,
      onStatusUpdate: (status) {},
    );

    AppHaptics.heavy();
    widget.onBotCreated(bot);
    Navigator.pop(context);
    AppSnackbar.success(context, 'Bot "${config.name}" criado com sucesso!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(
        title: 'Criar Novo Bot',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInWidget(
                child: _buildBasicInfoSection(),
              ),
              SizedBox(height: AppSpacing.xl),
              FadeInWidget(
                delay: Duration(milliseconds: 100),
                child: _buildStrategySection(),
              ),
              SizedBox(height: AppSpacing.xl),
              FadeInWidget(
                delay: Duration(milliseconds: 200),
                child: _buildMarketSection(),
              ),
              SizedBox(height: AppSpacing.xl),
              FadeInWidget(
                delay: Duration(milliseconds: 300),
                child: _buildStakeSection(),
              ),
              SizedBox(height: AppSpacing.xl),
              FadeInWidget(
                delay: Duration(milliseconds: 400),
                child: _buildAdvancedSection(),
              ),
              SizedBox(height: AppSpacing.massive),
              FadeInWidget(
                delay: Duration(milliseconds: 500),
                child: PrimaryButton(
                  text: 'Criar Bot',
                  icon: Icons.add_circle_rounded,
                  onPressed: _createBot,
                  expanded: true,
                ),
              ),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações Básicas',
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Nome do Bot',
                hint: 'Ex: Martingale Master',
                prefix: Icon(Icons.smart_toy_rounded),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Nome obrigatório';
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _descriptionController,
                label: 'Descrição',
                hint: 'Descreva a estratégia do bot',
                prefix: Icon(Icons.description_rounded),
                maxLines: 2,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Descrição obrigatória';
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStrategySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estratégia',
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tipo de Estratégia',
                style: context.textStyles.titleSmall,
              ),
              SizedBox(height: AppSpacing.sm),
              _buildStrategyChips(),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Modo de Recuperação',
                style: context.textStyles.titleSmall,
              ),
              SizedBox(height: AppSpacing.sm),
              _buildRecoveryModeChips(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStrategyChips() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: BotStrategy.values.map((strategy) {
        final isSelected = _selectedStrategy == strategy;
        return FilterChip(
          label: Text(_getStrategyName(strategy)),
          selected: isSelected,
          onSelected: (selected) {
            AppHaptics.light();
            setState(() => _selectedStrategy = strategy);
          },
          backgroundColor: context.colors.surfaceVariant,
          selectedColor: AppColors.primary.withOpacity(0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: context.textStyles.labelMedium?.copyWith(
            color: isSelected ? AppColors.primary : context.colors.onSurface,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecoveryModeChips() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: RecoveryMode.values.map((mode) {
        final isSelected = _selectedRecoveryMode == mode;
        return FilterChip(
          label: Text(_getRecoveryModeName(mode)),
          selected: isSelected,
          onSelected: (selected) {
            AppHaptics.light();
            setState(() => _selectedRecoveryMode = mode);
          },
          backgroundColor: context.colors.surfaceVariant,
          selectedColor: AppColors.success.withOpacity(0.2),
          checkmarkColor: AppColors.success,
          labelStyle: context.textStyles.labelMedium?.copyWith(
            color: isSelected ? AppColors.success : context.colors.onSurface,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMarketSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mercado',
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Símbolo',
                style: context.textStyles.titleSmall,
              ),
              SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _markets.map((market) {
                  final isSelected = _selectedMarket == market;
                  return FilterChip(
                    label: Text(market),
                    selected: isSelected,
                    onSelected: (selected) {
                      AppHaptics.light();
                      setState(() => _selectedMarket = market);
                    },
                    backgroundColor: context.colors.surfaceVariant,
                    selectedColor: AppColors.info.withOpacity(0.2),
                    checkmarkColor: AppColors.info,
                    labelStyle: context.textStyles.labelMedium?.copyWith(
                      color: isSelected ? AppColors.info : context.colors.onSurface,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                'Tipo de Contrato',
                style: context.textStyles.titleSmall,
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 16,
                              color: _selectedContractType == 'CALL'
                                  ? AppColors.success
                                  : context.colors.onSurfaceVariant,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text('CALL'),
                          ],
                        ),
                      ),
                      selected: _selectedContractType == 'CALL',
                      onSelected: (selected) {
                        AppHaptics.light();
                        setState(() => _selectedContractType = 'CALL');
                      },
                      backgroundColor: context.colors.surfaceVariant,
                      selectedColor: AppColors.success.withOpacity(0.2),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ChoiceChip(
                      label: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 16,
                              color: _selectedContractType == 'PUT'
                                  ? AppColors.error
                                  : context.colors.onSurfaceVariant,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text('PUT'),
                          ],
                        ),
                      ),
                      selected: _selectedContractType == 'PUT',
                      onSelected: (selected) {
                        AppHaptics.light();
                        setState(() => _selectedContractType = 'PUT');
                      },
                      backgroundColor: context.colors.surfaceVariant,
                      selectedColor: AppColors.error.withOpacity(0.2),
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

  Widget _buildStakeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações Financeiras',
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              AppTextField(
                controller: _stakeController,
                label: 'Stake Inicial (\$)',
                hint: '0.35',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                prefix: Icon(Icons.attach_money_rounded),
                validator: (value) {
                  final stake = double.tryParse(value?.replaceAll(',', '.') ?? '');
                  if (stake == null || stake < 0.35) {
                    return 'Mínimo: \$0.35';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _maxStakeController,
                label: 'Stake Máximo (\$)',
                hint: '10.00',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                prefix: Icon(Icons.trending_up_rounded),
                validator: (value) {
                  final maxStake = double.tryParse(value?.replaceAll(',', '.') ?? '');
                  final initialStake = double.tryParse(_stakeController.text.replaceAll(',', '.') ?? '');
                  if (maxStake == null || maxStake <= 0) {
                    return 'Valor inválido';
                  }
                  if (initialStake != null && maxStake < initialStake) {
                    return 'Deve ser maior que o stake inicial';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _targetProfitController,
                label: 'Target Profit (\$)',
                hint: '5.00',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                prefix: Icon(Icons.flag_rounded),
                validator: (value) {
                  final target = double.tryParse(value?.replaceAll(',', '.') ?? '');
                  if (target == null || target <= 0) {
                    return 'Deve ser maior que 0';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurações Avançadas',
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              AppTextField(
                controller: _maxLossesController,
                label: 'Max Perdas Consecutivas',
                hint: '7',
                keyboardType: TextInputType.number,
                prefix: Icon(Icons.warning_rounded),
                validator: (value) {
                  final maxLosses = int.tryParse(value ?? '');
                  if (maxLosses == null || maxLosses < 1) {
                    return 'Mínimo: 1';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                title: Text('Usar RSI', style: context.textStyles.titleSmall),
                subtitle: Text(
                  'Análise de Índice de Força Relativa',
                  style: context.textStyles.bodySmall,
                ),
                value: _useRSI,
                onChanged: (value) {
                  AppHaptics.light();
                  setState(() => _useRSI = value);
                },
                activeColor: AppColors.primary,
              ),
              if (_useRSI) ...[
                SizedBox(height: AppSpacing.md),
                Text(
                  'Condições de Entrada',
                  style: context.textStyles.titleSmall,
                ),
                SizedBox(height: AppSpacing.sm),
                _buildEntryConditionChips(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntryConditionChips() {
    final conditions = [
      EntryCondition.immediate,
      EntryCondition.rsiOversold,
      EntryCondition.rsiOverbought,
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: conditions.map((condition) {
        final isSelected = _selectedConditions.contains(condition);
        return FilterChip(
          label: Text(_getConditionName(condition)),
          selected: isSelected,
          onSelected: (selected) {
            AppHaptics.light();
            setState(() {
              if (selected) {
                _selectedConditions.add(condition);
              } else {
                _selectedConditions.remove(condition);
              }
            });
          },
          backgroundColor: context.colors.surfaceVariant,
          selectedColor: AppColors.warning.withOpacity(0.2),
          checkmarkColor: AppColors.warning,
          labelStyle: context.textStyles.labelSmall?.copyWith(
            color: isSelected ? AppColors.warning : context.colors.onSurface,
          ),
        );
      }).toList(),
    );
  }

  String _getStrategyName(BotStrategy strategy) {
    switch (strategy) {
      case BotStrategy.martingale:
        return 'Martingale';
      case BotStrategy.fibonacci:
        return 'Fibonacci';
      case BotStrategy.dalembert:
        return "D'Alembert";
      case BotStrategy.adaptive:
        return 'Adaptive';
      default:
        return 'Desconhecida';
    }
  }

  String _getRecoveryModeName(RecoveryMode mode) {
    switch (mode) {
      case RecoveryMode.conservative:
        return 'Conservador';
      case RecoveryMode.moderate:
        return 'Moderado';
      case RecoveryMode.intelligent:
        return 'Inteligente';
      default:
        return 'Desconhecido';
    }
  }

  String _getConditionName(EntryCondition condition) {
    switch (condition) {
      case EntryCondition.immediate:
        return 'Imediato';
      case EntryCondition.rsiOversold:
        return 'RSI Sobrevendido';
      case EntryCondition.rsiOverbought:
        return 'RSI Sobrecomprado';
      default:
        return 'Desconhecida';
    }
  }
}
// lib/bot_create_screen.dart
// Tela para criar novos bots personalizados
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'bot_engine.dart';
import 'styles.dart';

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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
        title: const Text('Criar Bot Personalizado'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome do Bot
            FadeInWidget(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuração Básica',
                    style: context.textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Bot',
                      hintText: 'Ex: Bot Agressivo',
                      prefixIcon: Icon(Icons.smart_toy_rounded),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Descrição
            FadeInWidget(
              delay: const Duration(milliseconds: 100),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  hintText: 'Descreva a estratégia do seu bot...',
                  prefixIcon: Icon(Icons.description_rounded),
                  alignLabelWithHint: true,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Stake Inicial
            FadeInWidget(
              delay: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Investimento Inicial',
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InfoCard(
                    icon: Icons.attach_money_rounded,
                    title: 'Stake Inicial',
                    subtitle: '\$${_initialStake.toStringAsFixed(2)}',
                    color: AppColors.success,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () {
                        AppHaptics.light();
                        _openStakeModal();
                      },
                    ),
                    onTap: () {
                      AppHaptics.light();
                      _openStakeModal();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Estratégia
            FadeInWidget(
              delay: const Duration(milliseconds: 300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estratégia de Trading',
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<BotStrategy>(
                    value: _selectedStrategy,
                    decoration: const InputDecoration(
                      labelText: 'Selecione a Estratégia',
                      prefixIcon: Icon(Icons.psychology_rounded),
                    ),
                    items: BotStrategy.values.map((strategy) {
                      return DropdownMenuItem(
                        value: strategy,
                        child: Text(_getStrategyName(strategy)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        AppHaptics.selection();
                        setState(() => _selectedStrategy = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: context.colors.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: context.colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _getStrategyDescription(_selectedStrategy),
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Mercado
            FadeInWidget(
              delay: const Duration(milliseconds: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configurações de Mercado',
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: _selectedMarket,
                    decoration: const InputDecoration(
                      labelText: 'Mercado',
                      prefixIcon: Icon(Icons.show_chart_rounded),
                    ),
                    items: _marketOptions.map((market) {
                      return DropdownMenuItem(
                        value: market,
                        child: Text(market),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        AppHaptics.selection();
                        setState(() => _selectedMarket = value);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Recovery Mode
            FadeInWidget(
              delay: const Duration(milliseconds: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo de Recuperação',
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<RecoveryMode>(
                    value: _recoveryMode,
                    decoration: const InputDecoration(
                      labelText: 'Recovery Mode',
                      prefixIcon: Icon(Icons.restore_rounded),
                    ),
                    items: RecoveryMode.values.map((mode) {
                      return DropdownMenuItem(
                        value: mode,
                        child: Text(_getRecoveryModeName(mode)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        AppHaptics.selection();
                        setState(() => _recoveryMode = value);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.massive),

            // Botão Criar
            FadeInWidget(
              delay: const Duration(milliseconds: 600),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedPrimaryButton(
                  text: 'Criar Bot',
                  icon: Icons.rocket_launch_rounded,
                  onPressed: _createBot,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _openStakeModal() {
    final controller = TextEditingController(
      text: _initialStake.toStringAsFixed(2),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Definir Stake Inicial',
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: context.textStyles.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: context.textStyles.headlineMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                hintText: '10.00',
                helperText: 'Valor mínimo: \$0.35',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      AppHaptics.light();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final value = double.tryParse(
                        controller.text.replaceAll(',', '.'),
                      );
                      if (value != null && value >= 0.35) {
                        AppHaptics.success();
                        setState(() => _initialStake = value);
                        Navigator.pop(context);
                      } else {
                        AppHaptics.error();
                        AppSnackbar.error(
                          context,
                          'Insira um valor válido (mínimo \$0.35)',
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createBot() {
    if (_nameController.text.trim().isEmpty) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Por favor, insira um nome para o bot');
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
    
    AppSnackbar.success(context, 'Bot "${bot.config.name}" criado com sucesso!');
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
      case BotStrategy.conservative:
        return 'Conservador';
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
      case BotStrategy.conservative:
        return 'Mantém stake fixo. Menor risco, retornos estáveis.';
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
// lib/bot_create_screen.dart
// Sistema de construção de bots por blocos
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'bot_engine.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
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
  
  // Block 1: Contract Type
  String _contractType = 'risefall';
  String _direction = 'CALL';
  int _digitPrediction = 5;
  int _multiplier = 10;
  
  // Block 2: Market
  String _selectedMarket = 'R_100';
  
  // Block 3: Stake Configuration
  double _initialStake = 1.0;
  bool _useProgression = true;
  String _progressionType = 'martingale';
  double _progressionMultiplier = 2.0;
  
  // Block 4: Duration
  String _durationType = 't';
  int _durationValue = 5;
  
  // Block 5: Risk Management
  double _stopLoss = 100.0;
  double _takeProfit = 50.0;
  int _maxLossStreak = 5;
  
  // Block 6: Timing
  int _tradeInterval = 10; // seconds
  bool _useSmartTiming = false;

  final Map<String, String> _contractTypes = {
    'risefall': 'Rise/Fall',
    'higherlower': 'Higher/Lower',
    'evenodd': 'Even/Odd',
    'matchdiffer': 'Match/Differ',
    'overunder': 'Over/Under',
    'digits': 'Digits',
    'multipliers': 'Multipliers',
    'accumulators': 'Accumulators',
  };

  final Map<String, String> _allMarkets = {
    'R_10': 'Volatility 10',
    'R_25': 'Volatility 25',
    'R_50': 'Volatility 50',
    'R_75': 'Volatility 75',
    'R_100': 'Volatility 100',
    '1HZ10V': 'Volatility 10 (1s)',
    '1HZ25V': 'Volatility 25 (1s)',
    '1HZ50V': 'Volatility 50 (1s)',
    '1HZ75V': 'Volatility 75 (1s)',
    '1HZ100V': 'Volatility 100 (1s)',
    'BOOM300N': 'Boom 300',
    'BOOM500': 'Boom 500',
    'BOOM1000': 'Boom 1000',
    'CRASH300N': 'Crash 300',
    'CRASH500': 'Crash 500',
    'CRASH1000': 'Crash 1000',
    'STPRNG': 'Step Index',
    'JD10': 'Jump 10',
    'JD25': 'Jump 25',
    'JD50': 'Jump 50',
    'JD75': 'Jump 75',
    'JD100': 'Jump 100',
  };

  final Map<String, String> _progressionTypes = {
    'martingale': 'Martingale (2x após perda)',
    'fibonacci': 'Fibonacci (sequência)',
    'dalembert': "D'Alembert (+1 após perda)",
    'fixed': 'Fixo (sem progressão)',
    'custom': 'Custom (definir multiplicador)',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: SecondaryAppBar(
        title: 'Construtor de Bot',
        onBack: () {
          AppHaptics.light();
          Navigator.pop(context);
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Header
                FadeInWidget(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.extension_rounded, size: 32, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sistema de Blocos',
                                style: context.textStyles.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Configure cada aspecto do seu bot',
                                style: context.textStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Block 1: Nome
                _buildBlock(
                  number: '1',
                  title: 'Nome do Bot',
                  icon: Icons.label_rounded,
                  color: AppColors.primary,
                  delay: 50,
                  child: AppTextField(
                    controller: _nameController,
                    label: 'Nome',
                    hint: 'Meu Bot Personalizado',
                    validator: (v) => v?.trim().isEmpty ?? true ? 'Obrigatório' : null,
                  ),
                ),

                // Block 2: Contract Type
                _buildBlock(
                  number: '2',
                  title: 'Tipo de Contrato',
                  icon: Icons.swap_calls_rounded,
                  color: AppColors.secondary,
                  delay: 100,
                  child: Column(
                    children: [
                      _buildContractTypeGrid(),
                      if (_needsDirection) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildDirectionSelector(),
                      ],
                      if (_needsDigitPrediction) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildDigitPrediction(),
                      ],
                      if (_contractType == 'multipliers') ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildMultiplierSelector(),
                      ],
                    ],
                  ),
                ),

                // Block 3: Market
                _buildBlock(
                  number: '3',
                  title: 'Mercado',
                  icon: Icons.show_chart_rounded,
                  color: AppColors.tertiary,
                  delay: 150,
                  child: _buildMarketSelector(),
                ),

                // Block 4: Duration
                _buildBlock(
                  number: '4',
                  title: 'Duração',
                  icon: Icons.schedule_rounded,
                  color: AppColors.info,
                  delay: 200,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDurationTypeSelector(),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildDurationValueInput(),
                      ),
                    ],
                  ),
                ),

                // Block 5: Stake & Progression
                _buildBlock(
                  number: '5',
                  title: 'Stake & Progressão',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                  delay: 250,
                  child: Column(
                    children: [
                      _buildStakeInput(),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile(
                        title: const Text('Usar Progressão'),
                        subtitle: const Text('Aumentar stake após perdas'),
                        value: _useProgression,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _useProgression = v);
                        },
                      ),
                      if (_useProgression) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildProgressionSelector(),
                        if (_progressionType == 'custom') ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildProgressionMultiplierInput(),
                        ],
                      ],
                    ],
                  ),
                ),

                // Block 6: Risk Management
                _buildBlock(
                  number: '6',
                  title: 'Gerenciamento de Risco',
                  icon: Icons.shield_rounded,
                  color: AppColors.warning,
                  delay: 300,
                  child: Column(
                    children: [
                      _buildRiskInput(
                        label: 'Stop Loss',
                        value: _stopLoss,
                        onChanged: (v) => setState(() => _stopLoss = v),
                        icon: Icons.trending_down_rounded,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildRiskInput(
                        label: 'Take Profit',
                        value: _takeProfit,
                        onChanged: (v) => setState(() => _takeProfit = v),
                        icon: Icons.trending_up_rounded,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildMaxStreakInput(),
                    ],
                  ),
                ),

                // Block 7: Timing
                _buildBlock(
                  number: '7',
                  title: 'Timing',
                  icon: Icons.timer_rounded,
                  color: AppColors.error,
                  delay: 350,
                  child: Column(
                    children: [
                      _buildIntervalInput(),
                      const SizedBox(height: AppSpacing.md),
                      SwitchListTile(
                        title: const Text('Smart Timing'),
                        subtitle: const Text('Aguardar melhores condições'),
                        value: _useSmartTiming,
                        onChanged: (v) {
                          AppHaptics.selection();
                          setState(() => _useSmartTiming = v);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.massive),
              ],
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: context.surface,
              border: Border(
                top: BorderSide(
                  color: context.colors.outlineVariant,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                text: 'Criar Bot',
                icon: Icons.rocket_launch_rounded,
                onPressed: _createBot,
                expanded: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock({
    required String number,
    required String title,
    required IconData icon,
    required Color color,
    required int delay,
    required Widget child,
  }) {
    return FadeInWidget(
      delay: Duration(milliseconds: delay),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: context.textStyles.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedCard(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildContractTypeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.5,
      ),
      itemCount: _contractTypes.length,
      itemBuilder: (context, index) {
        final entry = _contractTypes.entries.elementAt(index);
        final isSelected = _contractType == entry.key;
        return AnimatedContainer(
          duration: AppMotion.short,
          child: FilterChip(
            selected: isSelected,
            label: Text(entry.value, style: context.textStyles.labelSmall),
            onSelected: (_) {
              AppHaptics.selection();
              setState(() => _contractType = entry.key);
            },
          ),
        );
      },
    );
  }

  Widget _buildDirectionSelector() {
    return Row(
      children: ['CALL', 'PUT'].map((dir) {
        final isSelected = _direction == dir;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    dir == 'CALL' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(dir),
                ],
              ),
              onSelected: (_) {
                AppHaptics.selection();
                setState(() => _direction = dir);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDigitPrediction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Predição de Dígito', style: context.textStyles.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: List.generate(10, (i) {
            final isSelected = _digitPrediction == i;
            return FilterChip(
              selected: isSelected,
              label: Text(i.toString()),
              onSelected: (_) {
                AppHaptics.selection();
                setState(() => _digitPrediction = i);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMultiplierSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Multiplicador', style: context.textStyles.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        Slider(
          value: _multiplier.toDouble(),
          min: 1,
          max: 1000,
          divisions: 999,
          label: '${_multiplier}x',
          onChanged: (v) => setState(() => _multiplier = v.round()),
        ),
        Text('${_multiplier}x', style: context.textStyles.titleMedium),
      ],
    );
  }

  Widget _buildMarketSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedMarket,
      decoration: const InputDecoration(
        labelText: 'Selecionar Mercado',
        border: OutlineInputBorder(),
      ),
      items: _allMarkets.entries.map((e) {
        return DropdownMenuItem(
          value: e.key,
          child: Text('${e.key} - ${e.value}'),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) {
          AppHaptics.selection();
          setState(() => _selectedMarket = v);
        }
      },
    );
  }

  Widget _buildDurationTypeSelector() {
    final types = {'t': 'Ticks', 's': 'Segundos', 'm': 'Minutos', 'h': 'Horas', 'd': 'Dias'};
    return DropdownButtonFormField<String>(
      value: _durationType,
      decoration: const InputDecoration(
        labelText: 'Tipo',
        border: OutlineInputBorder(),
      ),
      items: types.entries.map((e) {
        return DropdownMenuItem(value: e.key, child: Text(e.value));
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _durationType = v);
      },
    );
  }

  Widget _buildDurationValueInput() {
    return TextFormField(
      initialValue: _durationValue.toString(),
      decoration: const InputDecoration(
        labelText: 'Valor',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) {
        final val = int.tryParse(v);
        if (val != null) setState(() => _durationValue = val);
      },
    );
  }

  Widget _buildStakeInput() {
    return TextFormField(
      initialValue: _initialStake.toStringAsFixed(2),
      decoration: const InputDecoration(
        labelText: 'Stake Inicial',
        prefixText: '\$ ',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      onChanged: (v) {
        final val = double.tryParse(v);
        if (val != null) setState(() => _initialStake = val);
      },
    );
  }

  Widget _buildProgressionSelector() {
    return DropdownButtonFormField<String>(
      value: _progressionType,
      decoration: const InputDecoration(
        labelText: 'Tipo de Progressão',
        border: OutlineInputBorder(),
      ),
      items: _progressionTypes.entries.map((e) {
        return DropdownMenuItem(value: e.key, child: Text(e.value));
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _progressionType = v);
      },
    );
  }

  Widget _buildProgressionMultiplierInput() {
    return TextFormField(
      initialValue: _progressionMultiplier.toStringAsFixed(2),
      decoration: const InputDecoration(
        labelText: 'Multiplicador Custom',
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      onChanged: (v) {
        final val = double.tryParse(v);
        if (val != null) setState(() => _progressionMultiplier = val);
      },
    );
  }

  Widget _buildRiskInput({
    required String label,
    required double value,
    required Function(double) onChanged,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      initialValue: value.toStringAsFixed(2),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        suffixText: 'USD',
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      onChanged: (v) {
        final val = double.tryParse(v);
        if (val != null) onChanged(val);
      },
    );
  }

  Widget _buildMaxStreakInput() {
    return TextFormField(
      initialValue: _maxLossStreak.toString(),
      decoration: const InputDecoration(
        labelText: 'Máximo de Perdas Consecutivas',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) {
        final val = int.tryParse(v);
        if (val != null) setState(() => _maxLossStreak = val);
      },
    );
  }

  Widget _buildIntervalInput() {
    return TextFormField(
      initialValue: _tradeInterval.toString(),
      decoration: const InputDecoration(
        labelText: 'Intervalo entre Trades (segundos)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) {
        final val = int.tryParse(v);
        if (val != null) setState(() => _tradeInterval = val);
      },
    );
  }

  bool get _needsDirection => ['risefall', 'higherlower', 'multipliers'].contains(_contractType);
  bool get _needsDigitPrediction => ['matchdiffer', 'overunder', 'digits'].contains(_contractType);

  void _createBot() {
    if (!_formKey.currentState!.validate()) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Preencha todos os campos obrigatórios');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Digite um nome para o bot');
      return;
    }

    AppHaptics.success();
    
    final botConfig = {
      'name': _nameController.text.trim(),
      'contractType': _contractType,
      'direction': _direction,
      'digitPrediction': _digitPrediction,
      'multiplier': _multiplier,
      'market': _selectedMarket,
      'durationType': _durationType,
      'durationValue': _durationValue,
      'initialStake': _initialStake,
      'useProgression': _useProgression,
      'progressionType': _progressionType,
      'progressionMultiplier': _progressionMultiplier,
      'stopLoss': _stopLoss,
      'takeProfit': _takeProfit,
      'maxLossStreak': _maxLossStreak,
      'tradeInterval': _tradeInterval,
      'useSmartTiming': _useSmartTiming,
    };

    // TODO: Implementar criação real do bot com a configuração
    debugPrint('Bot criado: $botConfig');
    
    Navigator.pop(context);
    AppSnackbar.success(context, 'Bot "${_nameController.text.trim()}" criado com sucesso!');
  }
}
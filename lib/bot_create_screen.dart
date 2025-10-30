// bot_create_screen.dart - Sistema avançado de criação de bots (CORRIGIDO)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'bot_engine.dart';
import 'bot_configuration.dart';
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

class _CreateBotScreenState extends State<CreateBotScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _jsCodeController = TextEditingController();

  int _creationMode = 0;
  BotStrategy _selectedStrategy = BotStrategy.martingale;

  String _contractType = 'CALL';
  String _market = 'R_100';
  int _duration = 5;
  String _durationUnit = 't';

  double _initialStake = 0.35;
  double? _maxStake = 50.0;
  double _targetProfit = 20.0;
  double _maxLoss = 100.0;
  int _maxConsecutiveLosses = 7;
  int _maxTrades = 100;
  double _estimatedPayout = 0.95;

  int _roundsPerCycle = 3;
  int _totalCycles = 10;
  double _extraProfitPercent = 10.0;
  bool _autoRecovery = true;

  double _trendMultiplier = 1.5;
  double _recoveryMultiplier = 1.2;
  int _trendFilter = 2;
  double _profitReinvestPercent = 50.0;

  double _consistencyMultiplier = 1.15;
  int _confidenceFilter = 2;
  double _patternConfidence = 0.6;

  RecoveryMode _recoveryMode = RecoveryMode.moderate;
  List<EntryCondition> _entryConditions = [EntryCondition.immediate];

  bool _useRSI = true;
  bool _useMACD = false;
  bool _useBollinger = false;
  bool _usePatternRecognition = false;

  final Map<BotStrategy, Map<String, String>> _strategyInfo = {
    BotStrategy.martingale: {
      'name': 'Martingale Pro',
      'description': 'Recuperação automática com cálculo realista de payout',
      'icon': '📈',
    },
    BotStrategy.progressiveReinvestment: {
      'name': 'Progressive Reinvestment',
      'description': 'Reinveste lucros e recupera perdas com fórmula inteligente',
      'icon': '🔄',
    },
    BotStrategy.trendyAdaptive: {
      'name': 'Trendy Adaptive',
      'description': 'Segue tendências com 3 fases: observação, execução e recuperação',
      'icon': '📊',
    },
    BotStrategy.adaptiveCompoundRecovery: {
      'name': 'ACS-R v3.0',
      'description': 'Sistema adaptativo com 4 módulos e aprendizado de padrão',
      'icon': '🧠',
    },
  };

  final Map<String, String> _markets = {
    'R_10': 'Volatility 10',
    'R_25': 'Volatility 25',
    'R_50': 'Volatility 50',
    'R_75': 'Volatility 75',
    'R_100': 'Volatility 100',
    '1HZ10V': 'Volatility 10 (1s)',
    '1HZ25V': 'Volatility 25 (1s)',
    '1HZ50V': 'Volatility 50 (1s)',
    '1HZ100V': 'Volatility 100 (1s)',
    'BOOM300N': 'Boom 300',
    'BOOM500': 'Boom 500',
    'BOOM1000': 'Boom 1000',
    'CRASH300N': 'Crash 300',
    'CRASH500': 'Crash 500',
    'CRASH1000': 'Crash 1000',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _creationMode = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _jsCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: AppBar(
        title: const Text('Criar Novo Bot'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Modo Blocos', icon: Icon(Icons.extension_rounded)),
            Tab(text: 'Código JS', icon: Icon(Icons.code_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBlockMode(),
          _buildJSMode(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.surface,
          border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: PrimaryButton(
            text: _creationMode == 0 ? 'Criar Bot' : 'Analisar e Criar',
            icon: _creationMode == 0 ? Icons.rocket_launch_rounded : Icons.auto_fix_high_rounded,
            onPressed: _createBot,
            expanded: true,
          ),
        ),
      ),
    );
  }

  Widget _buildBlockMode() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.xl),
          _buildBlock(
            number: '1',
            title: 'Informações Básicas',
            icon: Icons.info_rounded,
            color: AppColors.primary,
            delay: 50,
            child: Column(
              children: [
                AppTextField(
                  controller: _nameController,
                  label: 'Nome do Bot',
                  hint: 'Ex: Meu Bot Martingale',
                  validator: (v) => v?.trim().isEmpty ?? true ? 'Nome obrigatório' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Descrição',
                  hint: 'Descreva a estratégia do bot...',
                  maxLines: 2,
                ),
              ],
            ),
          ),
          _buildBlock(
            number: '2',
            title: 'Escolher Estratégia',
            icon: Icons.psychology_rounded,
            color: AppColors.secondary,
            delay: 100,
            child: _buildStrategySelector(),
          ),
          _buildBlock(
            number: '3',
            title: 'Contrato e Mercado',
            icon: Icons.show_chart_rounded,
            color: AppColors.tertiary,
            delay: 150,
            child: Column(
              children: [
                _buildContractTypeSelector(),
                const SizedBox(height: AppSpacing.md),
                _buildMarketSelector(),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _buildDurationInput()),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: _buildDurationUnitSelector()),
                  ],
                ),
              ],
            ),
          ),
          _buildBlock(
            number: '4',
            title: 'Configuração de Stake',
            icon: Icons.attach_money_rounded,
            color: AppColors.success,
            delay: 200,
            child: Column(
              children: [
                _buildStakeInput('Stake Inicial', _initialStake, (v) => setState(() => _initialStake = v), isRequired: true),
                const SizedBox(height: AppSpacing.md),
                _buildStakeInput('Stake Máximo', _maxStake ?? 50.0, (v) => setState(() => _maxStake = v)),
                const SizedBox(height: AppSpacing.md),
                _buildStakeInput('Payout Estimado (%)', _estimatedPayout * 100, (v) => setState(() => _estimatedPayout = v / 100)),
              ],
            ),
          ),
          if (_selectedStrategy != BotStrategy.martingale)
            _buildStrategyParameters(),
          _buildBlock(
            number: _selectedStrategy == BotStrategy.martingale ? '5' : '6',
            title: 'Gestão de Risco',
            icon: Icons.shield_rounded,
            color: AppColors.warning,
            delay: 250,
            child: Column(
              children: [
                _buildStakeInput('Meta de Lucro (\$)', _targetProfit, (v) => setState(() => _targetProfit = v)),
                const SizedBox(height: AppSpacing.md),
                _buildStakeInput('Perda Máxima (\$)', _maxLoss, (v) => setState(() => _maxLoss = v)),
                const SizedBox(height: AppSpacing.md),
                _buildIntInput('Perdas Consecutivas Máx.', _maxConsecutiveLosses, (v) => setState(() => _maxConsecutiveLosses = v)),
                const SizedBox(height: AppSpacing.md),
                _buildIntInput('Total de Trades Máx.', _maxTrades, (v) => setState(() => _maxTrades = v)),
              ],
            ),
          ),
          _buildBlock(
            number: _selectedStrategy == BotStrategy.martingale ? '6' : '7',
            title: 'Modo de Recuperação',
            icon: Icons.restore_rounded,
            color: AppColors.info,
            delay: 300,
            child: _buildRecoveryModeSelector(),
          ),
          _buildBlock(
            number: _selectedStrategy == BotStrategy.martingale ? '7' : '8',
            title: 'Análise Técnica (Opcional)',
            icon: Icons.analytics_rounded,
            color: AppColors.error,
            delay: 350,
            child: _buildTechnicalAnalysisToggles(),
          ),
          const SizedBox(height: AppSpacing.massive),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInWidget(
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
                  Text('Sistema de Blocos', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Configure cada aspecto do seu bot', style: context.textStyles.bodySmall),
                ],
              ),
            ),
          ],
        ),
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
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Center(
                    child: Text(number, style: context.textStyles.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AnimatedCard(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child)),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategySelector() {
    return Column(
      children: _strategyInfo.entries.map((entry) {
        final isSelected = _selectedStrategy == entry.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: InkWell(
            onTap: () {
              AppHaptics.selection();
              setState(() => _selectedStrategy = entry.key);
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : context.colors.surfaceContainer,
                border: Border.all(
                  color: isSelected ? AppColors.primary : context.colors.outlineVariant,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Text(entry.value['icon']!, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.value['name']!, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(entry.value['description']!, style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (isSelected) Icon(Icons.check_circle_rounded, color: AppColors.primary),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContractTypeSelector() {
    return DropdownButtonFormField<String>(
      value: _contractType,
      decoration: const InputDecoration(labelText: 'Tipo de Contrato', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'CALL', child: Text('CALL (Rise)')),
        DropdownMenuItem(value: 'PUT', child: Text('PUT (Fall)')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _contractType = v);
      },
    );
  }

  Widget _buildMarketSelector() {
    return DropdownButtonFormField<String>(
      value: _market,
      decoration: const InputDecoration(labelText: 'Mercado', border: OutlineInputBorder()),
      items: _markets.entries.map((e) => DropdownMenuItem(value: e.key, child: Text('${e.key} - ${e.value}'))).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _market = v);
      },
    );
  }

  Widget _buildDurationInput() {
    return TextFormField(
      initialValue: _duration.toString(),
      decoration: const InputDecoration(labelText: 'Duração', border: OutlineInputBorder()),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) {
        final val = int.tryParse(v);
        if (val != null) setState(() => _duration = val);
      },
    );
  }

  Widget _buildDurationUnitSelector() {
    return DropdownButtonFormField<String>(
      value: _durationUnit,
      decoration: const InputDecoration(labelText: 'Unidade', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 't', child: Text('Ticks')),
        DropdownMenuItem(value: 's', child: Text('Segundos')),
        DropdownMenuItem(value: 'm', child: Text('Minutos')),
        DropdownMenuItem(value: 'h', child: Text('Horas')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _durationUnit = v);
      },
    );
  }

  Widget _buildStakeInput(String label, double value, Function(double) onChanged, {bool isRequired = false}) {
    return TextFormField(
      initialValue: value.toStringAsFixed(2),
      decoration: InputDecoration(labelText: label, prefixText: '\$ ', border: const OutlineInputBorder()),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
      validator: isRequired ? (v) {
        final val = double.tryParse(v ?? '');
        if (val == null || val < 0.35) return 'Mínimo \$0.35';
        return null;
      } : null,
      onChanged: (v) {
        final val = double.tryParse(v);
        if (val != null) onChanged(val);
      },
    );
  }

  Widget _buildIntInput(String label, int value, Function(int) onChanged) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) {
        final val = int.tryParse(v);
        if (val != null) onChanged(val);
      },
    );
  }

  Widget _buildStrategyParameters() {
    switch (_selectedStrategy) {
      case BotStrategy.progressiveReinvestment:
        return _buildBlock(
          number: '5',
          title: 'Parâmetros - Progressive Reinvestment',
          icon: Icons.autorenew_rounded,
          color: AppColors.info,
          delay: 225,
          child: Column(
            children: [
              _buildIntInput('Rodadas por Ciclo (N)', _roundsPerCycle, (v) => setState(() => _roundsPerCycle = v)),
              const SizedBox(height: AppSpacing.md),
              _buildIntInput('Total de Ciclos (C)', _totalCycles, (v) => setState(() => _totalCycles = v)),
              const SizedBox(height: AppSpacing.md),
              _buildStakeInput('Lucro Extra na Recuperação (%)', _extraProfitPercent, (v) => setState(() => _extraProfitPercent = v)),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: const Text('Recuperação Automática'),
                subtitle: const Text('Recalcular stake após perda'),
                value: _autoRecovery,
                onChanged: (v) {
                  AppHaptics.selection();
                  setState(() => _autoRecovery = v);
                },
              ),
            ],
          ),
        );
      case BotStrategy.trendyAdaptive:
        return _buildBlock(
          number: '5',
          title: 'Parâmetros - Trendy Adaptive',
          icon: Icons.insights_rounded,
          color: AppColors.info,
          delay: 225,
          child: Column(
            children: [
              _buildStakeInput('Multiplicador de Tendência (Mt)', _trendMultiplier, (v) => setState(() => _trendMultiplier = v)),
              const SizedBox(height: AppSpacing.md),
              _buildStakeInput('Multiplicador de Recuperação (Mr)', _recoveryMultiplier, (v) => setState(() => _recoveryMultiplier = v)),
              const SizedBox(height: AppSpacing.md),
              _buildIntInput('Filtro de Tendência (F)', _trendFilter, (v) => setState(() => _trendFilter = v)),
              const SizedBox(height: AppSpacing.md),
              _buildStakeInput('% Lucro a Reinvestir', _profitReinvestPercent, (v) => setState(() => _profitReinvestPercent = v)),
            ],
          ),
        );
      case BotStrategy.adaptiveCompoundRecovery:
        return _buildBlock(
          number: '5',
          title: 'Parâmetros - ACS-R v3.0',
          icon: Icons.psychology_rounded,
          color: AppColors.info,
          delay: 225,
          child: Column(
            children: [
              _buildStakeInput('Multiplicador de Consistência (Mc)', _consistencyMultiplier, (v) => setState(() => _consistencyMultiplier = v)),
              const SizedBox(height: AppSpacing.md),
              _buildIntInput('Filtro de Confiança (F)', _confidenceFilter, (v) => setState(() => _confidenceFilter = v)),
              const SizedBox(height: AppSpacing.md),
              _buildStakeInput('Confiança Mínima no Padrão (%)', _patternConfidence * 100, (v) => setState(() => _patternConfidence = v / 100)),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRecoveryModeSelector() {
    return Column(
      children: RecoveryMode.values.map((mode) {
        return RadioListTile<RecoveryMode>(
          title: Text(_getRecoveryModeName(mode)),
          subtitle: Text(_getRecoveryModeDescription(mode)),
          value: mode,
          groupValue: _recoveryMode,
          onChanged: (v) {
            if (v != null) {
              AppHaptics.selection();
              setState(() => _recoveryMode = v);
            }
          },
        );
      }).toList(),
    );
  }

  String _getRecoveryModeName(RecoveryMode mode) {
    switch (mode) {
      case RecoveryMode.none: return 'Nenhum';
      case RecoveryMode.conservative: return 'Conservador';
      case RecoveryMode.moderate: return 'Moderado';
      case RecoveryMode.aggressive: return 'Agressivo';
      case RecoveryMode.intelligent: return 'Inteligente';
    }
  }

  String _getRecoveryModeDescription(RecoveryMode mode) {
    switch (mode) {
      case RecoveryMode.none: return 'Sem recuperação adicional';
      case RecoveryMode.conservative: return 'Aumento mínimo após 2 perdas';
      case RecoveryMode.moderate: return 'Aumento progressivo moderado';
      case RecoveryMode.aggressive: return 'Aumento imediato após perda';
      case RecoveryMode.intelligent: return 'Calcula recuperação baseada em perdas';
    }
  }

  Widget _buildTechnicalAnalysisToggles() {
    return Column(
      children: [
        SwitchListTile(title: const Text('RSI (Relative Strength Index)'), value: _useRSI, onChanged: (v) { AppHaptics.selection(); setState(() => _useRSI = v); }),
        SwitchListTile(title: const Text('MACD'), value: _useMACD, onChanged: (v) { AppHaptics.selection(); setState(() => _useMACD = v); }),
        SwitchListTile(title: const Text('Bandas de Bollinger'), value: _useBollinger, onChanged: (v) { AppHaptics.selection(); setState(() => _useBollinger = v); }),
        SwitchListTile(title: const Text('Reconhecimento de Padrões'), value: _usePatternRecognition, onChanged: (v) { AppHaptics.selection(); setState(() => _usePatternRecognition = v); }),
      ],
    );
  }

  Widget _buildJSMode() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        FadeInWidget(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.info.withOpacity(0.1), AppColors.primary.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.code_rounded, size: 32, color: AppColors.info),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Modo Código JS', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Cole seu código Deriv Bot e o sistema analisará automaticamente', style: context.textStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FadeInWidget(
          delay: const Duration(milliseconds: 100),
          child: AnimatedCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cole o código JavaScript do seu bot:', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _jsCodeController,
                    maxLines: 20,
                    decoration: InputDecoration(
                      hintText: '// Cole aqui o código do Deriv Bot\n// Exemplo:\nBot.init(function() {\n  // sua estratégia aqui\n});',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: context.colors.surfaceContainer,
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text('O sistema detectará automaticamente: estratégia, stake, mercado, duração e parâmetros', style: context.textStyles.bodySmall?.copyWith(color: AppColors.info)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FadeInWidget(
          delay: const Duration(milliseconds: 200),
          child: AnimatedCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_fix_high_rounded, color: AppColors.success),
                      const SizedBox(width: AppSpacing.sm),
                      Text('O que será detectado:', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDetectionItem('✓ Tipo de estratégia (Martingale, Progressive, etc)'),
                  _buildDetectionItem('✓ Stake inicial e progressão'),
                  _buildDetectionItem('✓ Mercado e tipo de contrato'),
                  _buildDetectionItem('✓ Duração e unidade'),
                  _buildDetectionItem('✓ Condições de entrada/saída'),
                  _buildDetectionItem('✓ Limites de risco'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: context.textStyles.bodySmall),
    );
  }

  void _createBot() {
    if (_creationMode == 0) {
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
      _createBotFromBlocks();
    } else {
      if (_jsCodeController.text.trim().isEmpty) {
        AppHaptics.error();
        AppSnackbar.error(context, 'Cole o código JavaScript do bot');
        return;
      }
      _createBotFromJS();
    }
  }

  void _createBotFromBlocks() {
    AppHaptics.success();
    List<EntryCondition> entryConditions = [EntryCondition.immediate];
    if (_selectedStrategy == BotStrategy.trendyAdaptive) entryConditions = [EntryCondition.trendSequence];
    else if (_selectedStrategy == BotStrategy.adaptiveCompoundRecovery) entryConditions = [EntryCondition.patternDetection];
    if (_useRSI) entryConditions.add(EntryCondition.rsiOversold);

    final config = BotConfiguration(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty ? _strategyInfo[_selectedStrategy]!['description']! : _descriptionController.text.trim(),
      strategy: _selectedStrategy,
      initialStake: _initialStake,
      market: _market,
      contractType: _contractType,
      duration: _duration,
      durationUnit: _durationUnit,
      recoveryMode: _recoveryMode,
      entryConditions: entryConditions,
      maxStake: _maxStake,
      maxLoss: _maxLoss,
      targetProfit: _targetProfit,
      maxConsecutiveLosses: _maxConsecutiveLosses,
      maxTrades: _maxTrades,
      estimatedPayout: _estimatedPayout,
      useRSI: _useRSI,
      useMACD: _useMACD,
      useBollinger: _useBollinger,
      usePatternRecognition: _usePatternRecognition,
      roundsPerCycle: _roundsPerCycle,
      totalCycles: _totalCycles,
      extraProfitPercent: _extraProfitPercent,
      autoRecovery: _autoRecovery,
      trendMultiplier: _trendMultiplier,
      recoveryMultiplier: _recoveryMultiplier,
      trendFilter: _trendFilter,
      profitReinvestPercent: _profitReinvestPercent,
      consistencyMultiplier: _consistencyMultiplier,
      confidenceFilter: _confidenceFilter,
      patternConfidence: _patternConfidence,
    );

    final bot = TradingBot(
      config: config,
      channel: widget.channel,
      onStatusUpdate: (_) {},
    );

    widget.onBotCreated(bot);
    Navigator.pop(context);
    AppSnackbar.success(context, 'Bot "${config.name}" criado com sucesso!');
  }

  void _createBotFromJS() {
    AppHaptics.medium();
    final jsCode = _jsCodeController.text.trim();
    final analysis = _analyzeJSCode(jsCode);

    if (analysis['error'] != null) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Erro ao analisar código: ${analysis['error']}');
      return;
    }

    final config = BotConfiguration(
      name: analysis['name'] ?? 'Bot JS Importado',
      description: analysis['description'] ?? 'Bot criado a partir de código JavaScript',
      strategy: analysis['strategy'] ?? BotStrategy.martingale,
      initialStake: analysis['initialStake'] ?? 0.35,
      market: analysis['market'] ?? 'R_100',
      contractType: analysis['contractType'] ?? 'CALL',
      duration: analysis['duration'] ?? 5,
      durationUnit: analysis['durationUnit'] ?? 't',
      recoveryMode: analysis['recoveryMode'] ?? RecoveryMode.moderate,
      entryConditions: analysis['entryConditions'] ?? [EntryCondition.immediate],
      maxStake: analysis['maxStake'],
      maxLoss: analysis['maxLoss'] ?? 100.0,
      targetProfit: analysis['targetProfit'] ?? 20.0,
      maxConsecutiveLosses: analysis['maxConsecutiveLosses'] ?? 7,
      maxTrades: analysis['maxTrades'] ?? 100,
      estimatedPayout: analysis['estimatedPayout'] ?? 0.95,
      roundsPerCycle: analysis['roundsPerCycle'] ?? 3,
      totalCycles: analysis['totalCycles'] ?? 10,
      extraProfitPercent: analysis['extraProfitPercent'] ?? 10.0,
      trendMultiplier: analysis['trendMultiplier'] ?? 1.5,
      recoveryMultiplier: analysis['recoveryMultiplier'] ?? 1.2,
      trendFilter: analysis['trendFilter'] ?? 2,
      consistencyMultiplier: analysis['consistencyMultiplier'] ?? 1.15,
      confidenceFilter: analysis['confidenceFilter'] ?? 2,
      patternConfidence: analysis['patternConfidence'] ?? 0.6,
    );

    final bot = TradingBot(
      config: config,
      channel: widget.channel,
      onStatusUpdate: (_) {},
    );

    widget.onBotCreated(bot);
    Navigator.pop(context);
    AppSnackbar.success(context, 'Bot "${config.name}" criado a partir do código JS!');
  }

  Map<String, dynamic> _analyzeJSCode(String code) {
    final result = <String, dynamic>{};

    try {
      if (code.toLowerCase().contains('martingale') || code.contains('stake * 2') || code.contains('stake *= 2')) {
        result['strategy'] = BotStrategy.martingale;
        result['name'] = 'Martingale Bot (JS)';
      } else if (code.contains('reinvest') || code.contains('compound') || code.contains('cycle')) {
        result['strategy'] = BotStrategy.progressiveReinvestment;
        result['name'] = 'Progressive Bot (JS)';
      } else if (code.contains('trend') || code.contains('pattern') || code.contains('adaptive')) {
        result['strategy'] = BotStrategy.trendyAdaptive;
        result['name'] = 'Trendy Bot (JS)';
      } else {
        result['strategy'] = BotStrategy.martingale;
        result['name'] = 'Custom Bot (JS)';
      }

      final stakePattern = RegExp(r'stake.*?[:=]\s*([0-9.]+)', caseSensitive: false);
      final stakeMatch = stakePattern.firstMatch(code);
      if (stakeMatch != null) {
        result['initialStake'] = double.tryParse(stakeMatch.group(1)!) ?? 0.35;
      }

      final marketPattern = RegExp(r'[R_]\d+|BOOM\d+|CRASH\d+|1HZ\d+V');
      final marketMatch = marketPattern.firstMatch(code);
      if (marketMatch != null) {
        result['market'] = marketMatch.group(0);
      }

      if (code.toUpperCase().contains('CALL') || code.contains('rise')) {
        result['contractType'] = 'CALL';
      } else if (code.toUpperCase().contains('PUT') || code.contains('fall')) {
        result['contractType'] = 'PUT';
      }

      final durationPattern = RegExp(r'duration.*?[:=]\s*(\d+)', caseSensitive: false);
      final durationMatch = durationPattern.firstMatch(code);
      if (durationMatch != null) {
        result['duration'] = int.tryParse(durationMatch.group(1)!) ?? 5;
      }

      if (code.contains('tick')) {
        result['durationUnit'] = 't';
      } else if (code.contains('second')) {
        result['durationUnit'] = 's';
      } else if (code.contains('minute')) {
        result['durationUnit'] = 'm';
      }

      final profitPattern = RegExp(r'profit.*?[:=]\s*([0-9.]+)', caseSensitive: false);
      final profitMatch = profitPattern.firstMatch(code);
      if (profitMatch != null) {
        result['targetProfit'] = double.tryParse(profitMatch.group(1)!) ?? 20.0;
      }

      final lossPattern = RegExp(r'loss.*?[:=]\s*([0-9.]+)', caseSensitive: false);
      final lossMatch = lossPattern.firstMatch(code);
      if (lossMatch != null) {
        result['maxLoss'] = double.tryParse(lossMatch.group(1)!) ?? 100.0;
      }

      final maxStakePattern = RegExp(r'max.*?stake.*?[:=]\s*([0-9.]+)', caseSensitive: false);
      final maxStakeMatch = maxStakePattern.firstMatch(code);
      if (maxStakeMatch != null) {
        result['maxStake'] = double.tryParse(maxStakeMatch.group(1)!);
      }

      final multiplierPattern = RegExp(r'multiplier.*?[:=]\s*([0-9.]+)', caseSensitive: false);
      final multiplierMatch = multiplierPattern.firstMatch(code);
      if (multiplierMatch != null) {
        final mult = double.tryParse(multiplierMatch.group(1)!);
        result['trendMultiplier'] = mult;
        result['recoveryMultiplier'] = mult;
      }

      final cyclesPattern = RegExp(r'cycle.*?[:=]\s*(\d+)', caseSensitive: false);
      final cyclesMatch = cyclesPattern.firstMatch(code);
      if (cyclesMatch != null) {
        result['totalCycles'] = int.tryParse(cyclesMatch.group(1)!) ?? 10;
      }

      final roundsPattern = RegExp(r'round.*?[:=]\s*(\d+)', caseSensitive: false);
      final roundsMatch = roundsPattern.firstMatch(code);
      if (roundsMatch != null) {
        result['roundsPerCycle'] = int.tryParse(roundsMatch.group(1)!) ?? 3;
      }

      result['description'] = 'Bot importado e analisado automaticamente do código JavaScript';
    } catch (e) {
      result['error'] = 'Erro ao analisar código: $e';
    }

    return result;
  }
}
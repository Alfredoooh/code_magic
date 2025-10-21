import 'package:flutter/material.dart';
import 'bot_strategies.dart';

class BotConfigScreen extends StatefulWidget {
  final BotConfig initialConfig;
  final Function(BotConfig) onSave;

  const BotConfigScreen({
    Key? key,
    required this.initialConfig,
    required this.onSave,
  }) : super(key: key);

  @override
  State<BotConfigScreen> createState() => _BotConfigScreenState();
}

class _BotConfigScreenState extends State<BotConfigScreen> {
  late BotConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig.copy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Configurações Avançadas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: () {
              widget.onSave(_config);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Configurações Básicas', [
            _buildSlider(
              'Stake Inicial',
              _config.initialStake,
              0.35,
              1000,
              (v) => setState(() => _config.initialStake = v),
              prefix: '\$',
            ),
            _buildSlider(
              'Stake Máximo',
              _config.maxStake,
              10,
              10000,
              (v) => setState(() => _config.maxStake = v),
              prefix: '\$',
            ),
            _buildSlider(
              'Stop Loss',
              _config.stopLoss,
              10,
              10000,
              (v) => setState(() => _config.stopLoss = v),
              prefix: '\$',
            ),
            _buildSlider(
              'Take Profit',
              _config.takeProfit,
              10,
              10000,
              (v) => setState(() => _config.takeProfit = v),
              prefix: '\$',
            ),
          ]),
          
          const SizedBox(height: 20),
          
          _buildSection('Recuperação de Perdas', [
            _buildSwitch(
              'Ativar Recuperação',
              _config.lossRecoveryEnabled,
              (v) => setState(() => _config.lossRecoveryEnabled = v),
            ),
            if (_config.lossRecoveryEnabled) ...[
              _buildDropdown(
                'Modo de Recuperação',
                _config.lossRecoveryMode,
                ['zero_profit', 'with_profit', 'aggressive'],
                {
                  'zero_profit': 'Sem Lucro (Zerar)',
                  'with_profit': 'Com Lucro',
                  'aggressive': 'Agressivo',
                },
                (v) => setState(() => _config.lossRecoveryMode = v),
              ),
              _buildSlider(
                'Multiplicador de Recuperação',
                _config.lossRecoveryMultiplier,
                1.1,
                5.0,
                (v) => setState(() => _config.lossRecoveryMultiplier = v),
                divisions: 39,
              ),
              if (_config.lossRecoveryMode == 'with_profit')
                _buildSlider(
                  'Lucro na Recuperação (%)',
                  _config.lossRecoveryProfit,
                  1,
                  50,
                  (v) => setState(() => _config.lossRecoveryProfit = v),
                  suffix: '%',
                ),
            ],
          ]),
          
          const SizedBox(height: 20),
          
          _buildSection('Acumulação Avançada', [
            _buildSwitch(
              'Ativar Acumulação',
              _config.accumulationEnabled,
              (v) => setState(() => _config.accumulationEnabled = v),
            ),
            if (_config.accumulationEnabled) ...[
              _buildSlider(
                'Máximo de Acumulações',
                _config.maxAccumulations.toDouble(),
                1,
                20,
                (v) => setState(() => _config.maxAccumulations = v.toInt()),
                divisions: 19,
              ),
              _buildSlider(
                'Percentual de Lucro para Acumular (%)',
                _config.accumulationProfitPercent,
                10,
                100,
                (v) => setState(() => _config.accumulationProfitPercent = v),
                suffix: '%',
              ),
              _buildSwitch(
                'Operar com Lucros Acumulados',
                _config.tradeWithAccumulatedProfit,
                (v) => setState(() => _config.tradeWithAccumulatedProfit = v),
              ),
              _buildSwitch(
                'Reinvestir Automaticamente',
                _config.autoReinvest,
                (v) => setState(() => _config.autoReinvest = v),
              ),
            ],
          ]),
          
          const SizedBox(height: 20),
          
          _buildSection('Auto Trade Avançado', [
            _buildSwitch(
              'Ativar Auto Trade',
              _config.autoTradeEnabled,
              (v) => setState(() => _config.autoTradeEnabled = v),
            ),
            if (_config.autoTradeEnabled) ...[
              _buildDropdown(
                'Trigger de Entrada',
                _config.autoTradeTrigger,
                ['fall_1min', 'rise_1min', 'volatility_spike', 'price_level'],
                {
                  'fall_1min': 'Queda de 1 Minuto',
                  'rise_1min': 'Subida de 1 Minuto',
                  'volatility_spike': 'Pico de Volatilidade',
                  'price_level': 'Nível de Preço',
                },
                (v) => setState(() => _config.autoTradeTrigger = v),
              ),
              _buildDropdown(
                'Direção da Operação',
                _config.autoTradeDirection,
                ['opposite', 'same', 'smart'],
                {
                  'opposite': 'Oposta ao Trigger',
                  'same': 'Mesma do Trigger',
                  'smart': 'Inteligente (IA)',
                },
                (v) => setState(() => _config.autoTradeDirection = v),
              ),
              _buildSlider(
                'Percentual de Queda/Subida (%)',
                _config.autoTradeThreshold,
                0.1,
                5.0,
                (v) => setState(() => _config.autoTradeThreshold = v),
                suffix: '%',
                divisions: 49,
              ),
              _buildSlider(
                'Tempo de Análise (segundos)',
                _config.autoTradeAnalysisPeriod.toDouble(),
                30,
                300,
                (v) => setState(() => _config.autoTradeAnalysisPeriod = v.toInt()),
                divisions: 27,
                suffix: 's',
              ),
            ],
          ]),
          
          const SizedBox(height: 20),
          
          _buildSection('Martingale Inteligente', [
            _buildSwitch(
              'Ativar Martingale',
              _config.martingaleEnabled,
              (v) => setState(() => _config.martingaleEnabled = v),
            ),
            if (_config.martingaleEnabled) ...[
              _buildSlider(
                'Multiplicador',
                _config.martingaleMultiplier,
                1.5,
                5.0,
                (v) => setState(() => _config.martingaleMultiplier = v),
                divisions: 35,
              ),
              _buildSlider(
                'Máximo de Níveis',
                _config.martingaleMaxLevels.toDouble(),
                3,
                15,
                (v) => setState(() => _config.martingaleMaxLevels = v.toInt()),
                divisions: 12,
              ),
              _buildSwitch(
                'Reset em Win',
                _config.martingaleResetOnWin,
                (v) => setState(() => _config.martingaleResetOnWin = v),
              ),
            ],
          ]),
          
          const SizedBox(height: 20),
          
          _buildSection('Análise de Mercado', [
            _buildSlider(
              'Período de Análise (ticks)',
              _config.analysisTickPeriod.toDouble(),
              10,
              500,
              (v) => setState(() => _config.analysisTickPeriod = v.toInt()),
              divisions: 49,
            ),
            _buildSwitch(
              'Usar Análise de Tendência',
              _config.useTrendAnalysis,
              (v) => setState(() => _config.useTrendAnalysis = v),
            ),
            _buildSwitch(
              'Usar Análise de Volatilidade',
              _config.useVolatilityAnalysis,
              (v) => setState(() => _config.useVolatilityAnalysis = v),
            ),
            _buildSwitch(
              'Usar Padrões de Dígitos',
              _config.useDigitPatterns,
              (v) => setState(() => _config.useDigitPatterns = v),
            ),
          ]),
          
          const SizedBox(height: 20),
          
          _buildSection('Limites de Segurança', [
            _buildSlider(
              'Máximo de Trades por Dia',
              _config.maxTradesPerDay.toDouble(),
              10,
              500,
              (v) => setState(() => _config.maxTradesPerDay = v.toInt()),
              divisions: 49,
            ),
            _buildSlider(
              'Perda Máxima Consecutiva',
              _config.maxConsecutiveLosses.toDouble(),
              3,
              20,
              (v) => setState(() => _config.maxConsecutiveLosses = v.toInt()),
              divisions: 17,
            ),
            _buildSwitch(
              'Parar em Drawdown',
              _config.stopOnDrawdown,
              (v) => setState(() => _config.stopOnDrawdown = v),
            ),
            if (_config.stopOnDrawdown)
              _buildSlider(
                'Drawdown Máximo (%)',
                _config.maxDrawdownPercent,
                5,
                50,
                (v) => setState(() => _config.maxDrawdownPercent = v),
                suffix: '%',
              ),
          ]),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1a1a1a)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String prefix = '',
    String suffix = '',
    int? divisions,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '$prefix${value.toStringAsFixed(divisions != null ? 1 : 2)}$suffix',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: const Color(0xFF007AFF),
            inactiveColor: const Color(0xFF1a1a1a),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF007AFF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> options,
    Map<String, String> labels,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: const Color(0xFF1a1a1a),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: const Color(0xFF1a1a1a),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            items: options.map((opt) => DropdownMenuItem(
              value: opt,
              child: Text(labels[opt] ?? opt),
            )).toList(),
            onChanged: (v) => onChanged(v!),
          ),
        ],
      ),
    );
  }
}

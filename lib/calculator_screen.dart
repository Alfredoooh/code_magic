import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'styles.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers para Profit/Loss
  final _stakeController = TextEditingController();
  final _multiplierController = TextEditingController();
  final _resultProfit = ValueNotifier<double?>(null);
  
  // Controllers para Risk Management
  final _balanceController = TextEditingController();
  final _riskPercentController = TextEditingController(text: '2');
  final _resultRisk = ValueNotifier<double?>(null);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stakeController.dispose();
    _multiplierController.dispose();
    _balanceController.dispose();
    _riskPercentController.dispose();
    _resultProfit.dispose();
    _resultRisk.dispose();
    super.dispose();
  }

  void _calculateProfit() {
    final stake = double.tryParse(_stakeController.text);
    final multiplier = double.tryParse(_multiplierController.text);
    
    if (stake != null && multiplier != null) {
      _resultProfit.value = stake * multiplier;
      HapticFeedback.mediumImpact();
    } else {
      AppStyles.showSnackBar(context, 'Preencha todos os campos', isError: true);
    }
  }

  void _calculateRisk() {
    final balance = double.tryParse(_balanceController.text);
    final riskPercent = double.tryParse(_riskPercentController.text);
    
    if (balance != null && riskPercent != null) {
      _resultRisk.value = (balance * riskPercent) / 100;
      HapticFeedback.mediumImpact();
    } else {
      AppStyles.showSnackBar(context, 'Preencha todos os campos', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppStyles.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppStyles.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Calculadoras',
          style: TextStyle(
            color: AppStyles.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppStyles.iosBlue,
          labelColor: AppStyles.iosBlue,
          unselectedLabelColor: AppStyles.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Lucro/Perda'),
            Tab(text: 'Risco'),
            Tab(text: 'Martingale'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfitLossCalculator(),
          _buildRiskCalculator(),
          _buildMartingaleCalculator(),
        ],
      ),
    );
  }

  Widget _buildProfitLossCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Calculadora de Lucro/Perda',
            style: TextStyle(
              color: AppStyles.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calcule seu potencial de lucro ou perda',
            style: TextStyle(
              color: AppStyles.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _stakeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor de Entrada (Stake)',
              prefixText: '\$ ',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
            style: const TextStyle(color: AppStyles.textPrimary),
          ),
          
          const SizedBox(height: 20),
          
          TextField(
            controller: _multiplierController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Multiplicador',
              prefixText: 'x',
              prefixIcon: Icon(Icons.close_rounded),
            ),
            style: const TextStyle(color: AppStyles.textPrimary),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _calculateProfit,
              child: const Text(
                'Calcular',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          ValueListenableBuilder<double?>(
            valueListenable: _resultProfit,
            builder: (context, result, _) {
              if (result == null) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppStyles.iosBlue.withOpacity(0.2),
                      AppStyles.iosBlue.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppStyles.iosBlue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Resultado',
                      style: TextStyle(
                        color: AppStyles.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${result.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppStyles.iosBlue,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lucro Potencial',
                      style: TextStyle(
                        color: AppStyles.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRiskCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Gestão de Risco',
            style: TextStyle(
              color: AppStyles.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calcule quanto arriscar por trade',
            style: TextStyle(
              color: AppStyles.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _balanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Saldo da Conta',
              prefixText: '\$ ',
              prefixIcon: Icon(Icons.account_balance_wallet_rounded),
            ),
            style: const TextStyle(color: AppStyles.textPrimary),
          ),
          
          const SizedBox(height: 20),
          
          TextField(
            controller: _riskPercentController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Risco por Trade',
              suffixText: '%',
              prefixIcon: Icon(Icons.percent_rounded),
              helperText: 'Recomendado: 1-2% por trade',
            ),
            style: const TextStyle(color: AppStyles.textPrimary),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _calculateRisk,
              child: const Text(
                'Calcular',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          ValueListenableBuilder<double?>(
            valueListenable: _resultRisk,
            builder: (context, result, _) {
              if (result == null) return const SizedBox.shrink();
              
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppStyles.iosGreen.withOpacity(0.2),
                      AppStyles.iosGreen.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppStyles.iosGreen.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Valor Máximo por Trade',
                      style: TextStyle(
                        color: AppStyles.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${result.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppStyles.iosGreen,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMartingaleCalculator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 80,
              color: AppStyles.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Em Desenvolvimento',
              style: TextStyle(
                color: AppStyles.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Calculadora de Martingale em breve',
              style: TextStyle(
                color: AppStyles.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
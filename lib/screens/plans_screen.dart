import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_ui_components.dart';
import '../services/plans_service.dart';
import '../models/plan_model.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({Key? key}) : super(key: key);

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  int _selectedPlanIndex = 1;
  List<PlanModel> _plans = [];
  bool _isLoading = true;
  String? _errorMessage;

  final PlansService _plansService = PlansService();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await _plansService.fetchPlans();
      setState(() {
        _plans = plans;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar planos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Planos',
      ),
      body: _isLoading
          ? _buildLoadingState(isDark)
          : _errorMessage != null
              ? _buildErrorState(isDark)
              : _buildPlansContent(isDark),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Carregando planos...',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIconCircle(
              icon: Icons.error_outline,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Erro desconhecido',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppPrimaryButton(
              text: 'Tentar novamente',
              onPressed: _loadPlans,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansContent(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              AppSectionTitle(
                text: 'Escolha seu plano',
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 8),
              Text(
                'Desbloqueie todo o potencial da plataforma',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        ..._plans.asMap().entries.map((entry) {
          final index = entry.key;
          final plan = entry.value;
          return _buildPlanCard(plan, index, isDark);
        }).toList(),
      ],
    );
  }

  Widget _buildPlanCard(PlanModel plan, int index, bool isDark) {
    final isSelected = _selectedPlanIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionTitle(
                      text: plan.name,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          plan.price,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          plan.period,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (plan.popular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${plan.tokens} tokens',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...plan.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isSelected
                  ? AppPrimaryButton(
                      text: 'Adquirir',
                      onPressed: () => _subscribeToPlan(plan),
                    )
                  : AppSecondaryButton(
                      text: 'Adquirir',
                      onPressed: () => _subscribeToPlan(plan),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subscribeToPlan(PlanModel plan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppDialogs.showError(
        context,
        'Erro',
        'Você precisa estar logado para adquirir um plano.',
      );
      return;
    }

    // Buscar dados do usuário
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};
    final userEmail = userData['email'] ?? user.email ?? 'Email não disponível';
    final userName = userData['username'] ?? 'Usuário';

    // Mostrar opções de pagamento
    _showPaymentMethodsDialog(plan, user.uid, userEmail, userName);
  }

  void _showPaymentMethodsDialog(PlanModel plan, String userId, String userEmail, String userName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context,
      height: 500,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              text: 'Escolha o método de pagamento',
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 8),
            Text(
              'Selecione como deseja pagar pelo plano ${plan.name}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildPaymentOption(
                    icon: Icons.credit_card,
                    title: 'Cartão de Crédito',
                    onTap: () {
                      Navigator.pop(context);
                      _sendPurchaseRequest(plan, userId, userEmail, userName, 'Cartão de Crédito');
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    icon: Icons.pix,
                    title: 'PIX',
                    onTap: () {
                      Navigator.pop(context);
                      _sendPurchaseRequest(plan, userId, userEmail, userName, 'PIX');
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    icon: Icons.receipt_long,
                    title: 'Boleto Bancário',
                    onTap: () {
                      Navigator.pop(context);
                      _sendPurchaseRequest(plan, userId, userEmail, userName, 'Boleto Bancário');
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    icon: Icons.swap_horiz,
                    title: 'Transferência Bancária',
                    onTap: () {
                      Navigator.pop(context);
                      _sendPurchaseRequest(plan, userId, userEmail, userName, 'Transferência Bancária');
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption(
                    icon: Icons.payment,
                    title: 'PayPal',
                    onTap: () {
                      Navigator.pop(context);
                      _sendPurchaseRequest(plan, userId, userEmail, userName, 'PayPal');
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSecondaryButton(
              text: 'Cancelar',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppSectionTitle(
                  text: title,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendPurchaseRequest(
    PlanModel plan,
    String userId,
    String userEmail,
    String userName,
    String paymentMethod,
  ) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  color: AppColors.primary,
                ),
                SizedBox(height: 16),
                Text(
                  'Enviando solicitação...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Criar solicitação de compra para os administradores
      await FirebaseFirestore.instance.collection('purchase_requests').add({
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'planName': plan.name,
        'planPrice': plan.price,
        'planPeriod': plan.period,
        'planTokens': plan.tokens,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      // Fechar loading
      Navigator.pop(context);

      // Mostrar mensagem de sucesso
      AppDialogs.showSuccess(
        context,
        'Solicitação Enviada!',
        'Sua solicitação de compra do plano ${plan.name} foi enviada aos administradores.\n\nVocê receberá um email com as instruções de pagamento em breve.\n\nPor favor, aguarde o contato.',
        onClose: () {
          Navigator.pop(context); // Voltar para tela anterior
        },
      );
    } catch (e) {
      // Fechar loading
      Navigator.pop(context);

      // Mostrar erro
      AppDialogs.showError(
        context,
        'Erro',
        'Ocorreu um erro ao enviar a solicitação: $e',
      );
    }
  }
}
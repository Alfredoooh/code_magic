import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/plans_service.dart';
import '../models/plan_model.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({Key? key}) : super(key: key);

  @override
  _PlansScreenState createState() => _PlansScreenState();
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
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(
            CupertinoIcons.chevron_back,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: Text(
          'Planos',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          CupertinoActivityIndicator(radius: 16),
          SizedBox(height: 20),
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
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              _errorMessage ?? 'Erro desconhecido',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            CupertinoButton(
              color: Color(0xFFFF444F),
              onPressed: _loadPlans,
              child: Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansContent(bool isDark) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Text(
                'Escolha seu plano',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
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
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Color(0xFFFF444F) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
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
                    Text(
                      plan.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          plan.price,
                          style: TextStyle(
                            color: Color(0xFFFF444F),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
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
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF444F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
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
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFFFF444F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${plan.tokens} tokens',
                style: TextStyle(
                  color: Color(0xFFFF444F),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 16),
            ...plan.features.map((feature) => Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: Color(0xFFFF444F),
                    size: 18,
                  ),
                  SizedBox(width: 10),
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
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: EdgeInsets.symmetric(vertical: 14),
                color: isSelected ? Color(0xFFFF444F) : (isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7)),
                borderRadius: BorderRadius.circular(12),
                onPressed: () => _subscribeToPlan(plan),
                child: Text(
                  'Adquirir',
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
      _showErrorDialog('Erro', 'Você precisa estar logado para adquirir um plano.');
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
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Escolha o método de pagamento'),
        message: Text('Selecione como deseja pagar pelo plano ${plan.name}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _sendPurchaseRequest(plan, userId, userEmail, userName, 'Cartão de Crédito');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.creditcard, color: CupertinoColors.activeBlue),
                SizedBox(width: 8),
                Text('Cartão de Crédito'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _sendPurchaseRequest(plan, userId, userEmail, userName, 'PIX');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.money_dollar_circle, color: CupertinoColors.activeBlue),
                SizedBox(width: 8),
                Text('PIX'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _sendPurchaseRequest(plan, userId, userEmail, userName, 'Boleto Bancário');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.barcode, color: CupertinoColors.activeBlue),
                SizedBox(width: 8),
                Text('Boleto Bancário'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _sendPurchaseRequest(plan, userId, userEmail, userName, 'Transferência Bancária');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_right_arrow_left, color: CupertinoColors.activeBlue),
                SizedBox(width: 8),
                Text('Transferência Bancária'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _sendPurchaseRequest(plan, userId, userEmail, userName, 'PayPal');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.globe, color: CupertinoColors.activeBlue),
                SizedBox(width: 8),
                Text('PayPal'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
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
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(radius: 16),
              SizedBox(height: 16),
              Text(
                'Enviando solicitação...',
                style: TextStyle(color: Colors.white),
              ),
            ],
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
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Row(
            children: [
              Icon(CupertinoIcons.check_mark_circled_solid, color: Color(0xFFFF444F)),
              SizedBox(width: 8),
              Text('Solicitação Enviada!'),
            ],
          ),
          content: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Sua solicitação de compra do plano ${plan.name} foi enviada aos administradores.\n\nVocê receberá um email com as instruções de pagamento em breve.\n\nPor favor, aguarde o contato.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('Entendido'),
              onPressed: () {
                Navigator.pop(context); // Fechar dialog
                Navigator.pop(context); // Voltar para tela anterior
              },
            ),
          ],
        ),
      );
    } catch (e) {
      // Fechar loading
      Navigator.pop(context);
      
      // Mostrar erro
      _showErrorDialog('Erro', 'Ocorreu um erro ao enviar a solicitação: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
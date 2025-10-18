// lib/screens/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_ui_components.dart';
import 'goals_widgets/goals_add_task_screen.dart';
import 'goals_widgets/goals_add_strategy_screen.dart';
import 'goals_widgets/goals_add_note_screen.dart';
import 'goals_widgets/goals_journal_screen.dart';
import 'goals_widgets/goals_checklist_screen.dart';

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Financeiro';
  DateTime? _selectedDeadline;
  late TabController _tabController;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Financeiro', 'icon': Icons.attach_money_rounded, 'color': Colors.green},
    {'name': 'Saúde', 'icon': Icons.favorite_rounded, 'color': Colors.red},
    {'name': 'Educação', 'icon': Icons.school_rounded, 'color': Colors.blue},
    {'name': 'Carreira', 'icon': Icons.work_rounded, 'color': Colors.orange},
    {'name': 'Pessoal', 'icon': Icons.person_rounded, 'color': Colors.purple},
    {'name': 'Outro', 'icon': Icons.flag_rounded, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _descriptionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showAddGoalModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              children: [
                SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.2),
                                    AppColors.primary.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.track_changes_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppSectionTitle(text: 'Nova Meta', fontSize: 22),
                                  Text(
                                    'Defina e acompanhe seus objetivos',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(context),
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                        SizedBox(height: 28),
                        AppFieldLabel(text: 'Título da Meta'),
                        AppTextField(
                          controller: _titleController,
                          hintText: 'Ex: Economizar R\$ 10.000',
                          prefixIcon: Icon(Icons.title_rounded, size: 20),
                        ),
                        SizedBox(height: 20),
                        AppFieldLabel(text: 'Descrição (Opcional)'),
                        AppTextField(
                          controller: _descriptionController,
                          hintText: 'Descreva sua meta em detalhes',
                          maxLines: 3,
                          prefixIcon: Icon(Icons.description_rounded, size: 20),
                        ),
                        SizedBox(height: 20),
                        AppFieldLabel(text: 'Categoria'),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category['name'];
                            return GestureDetector(
                              onTap: () {
                                setModalState(() => _selectedCategory = category['name']);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? LinearGradient(
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primaryLight,
                                          ],
                                        )
                                      : null,
                                  color: !isSelected
                                      ? (isDark
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder)
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.lightBorder),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      category['icon'],
                                      color: isSelected
                                          ? Colors.white
                                          : category['color'],
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      category['name'],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark ? Colors.white : Colors.black),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 20),
                        AppFieldLabel(text: 'Valor Alvo (Opcional)'),
                        AppTextField(
                          controller: _targetController,
                          hintText: 'Ex: 10000',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icon(Icons.monetization_on_rounded, size: 20),
                        ),
                        SizedBox(height: 20),
                        AppFieldLabel(text: 'Prazo (Opcional)'),
                        AppTextField(
                          hintText: _selectedDeadline == null
                              ? 'Selecione uma data'
                              : '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}',
                          enabled: false,
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 3650)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppColors.primary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setModalState(() => _selectedDeadline = date);
                            }
                          },
                          prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                        ),
                        SizedBox(height: 32),
                        AppPrimaryButton(
                          text: 'Criar Meta',
                          onPressed: _saveGoal,
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveGoal() async {
    if (_titleController.text.trim().isEmpty) {
      AppDialogs.showError(context, 'Erro', 'Por favor, insira um título para a meta');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppDialogs.showError(context, 'Erro', 'Você precisa estar logado');
        return;
      }

      await FirebaseFirestore.instance.collection('goals').add({
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'target': _targetController.text.isNotEmpty
            ? double.tryParse(_targetController.text) ?? 0
            : 0,
        'current': 0,
        'completed': false,
        'deadline': _selectedDeadline?.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _descriptionController.clear();
      _targetController.clear();
      setState(() {
        _selectedCategory = 'Financeiro';
        _selectedDeadline = null;
      });

      Navigator.pop(context);

      AppDialogs.showSuccess(
        context,
        'Sucesso!',
        'Meta criada com sucesso!',
      );
    } catch (e) {
      AppDialogs.showError(
        context,
        'Erro',
        'Erro ao criar meta. Tente novamente.',
      );
    }
  }

  Future<void> _updateProgress(String goalId, double current, double target) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: current.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Atualizar Progresso',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: controller,
              hintText: 'Valor atual',
              keyboardType: TextInputType.number,
              prefixIcon: Icon(Icons.edit_rounded, size: 20),
            ),
            SizedBox(height: 12),
            Text(
              'Meta: R\$ ${target.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null) {
                await FirebaseFirestore.instance
                    .collection('goals')
                    .doc(goalId)
                    .update({
                  'current': value,
                  'completed': value >= target,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Progresso atualizado!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: Text(
              'Salvar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGoal(String goalId) async {
    AppDialogs.showConfirmation(
      context,
      'Excluir Meta',
      'Tem certeza que deseja excluir esta meta? Esta ação não pode ser desfeita.',
      onConfirm: () async {
        try {
          await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meta excluída com sucesso'),
              backgroundColor: AppColors.success,
            ),
          );
        } catch (e) {
          AppDialogs.showError(context, 'Erro', 'Erro ao excluir meta');
        }
      },
      isDestructive: true,
      confirmText: 'Excluir',
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = _categories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => _categories.last,
    );
    return cat['icon'];
  }

  Color _getCategoryColor(String category) {
    final cat = _categories.firstWhere(
      (c) => c['name'] == category,
      orElse: () => _categories.last,
    );
    return cat['color'];
  }

  void _showOptionsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AppSectionTitle(text: 'Ferramentas', fontSize: 20),
            ),
            SizedBox(height: 16),
            _buildMenuOption(
              icon: Icons.task_alt_rounded,
              label: 'Adicionar Tarefa',
              color: Colors.blue,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalsAddTaskScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.lightbulb_rounded,
              label: 'Criar Estratégia',
              color: Colors.orange,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalsAddStrategyScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.note_add_rounded,
              label: 'Anotar Nota',
              color: Colors.green,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalsAddNoteScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.book_rounded,
              label: 'Diário de Trading',
              color: Colors.purple,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalsJournalScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
            _buildMenuOption(
              icon: Icons.checklist_rounded,
              label: 'Checklist Diário',
              color: Colors.teal,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoalsChecklistScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppPrimaryAppBar(
        title: 'Metas',
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.primary, size: 26),
            onPressed: _showAddGoalModal,
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white : Colors.black),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkSeparator : AppColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: AppColors.primary,
              indicatorWeight: 2.5,
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
              tabs: [
                Tab(text: 'Metas'),
                Tab(text: 'Tarefas'),
                Tab(text: 'Estratégias'),
                Tab(text: 'Notas'),
                Tab(text: 'Diário'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGoalsList(isDark, user),
                _buildComingSoon('Tarefas', Icons.task_alt_rounded, isDark),
                _buildComingSoon('Estratégias', Icons.lightbulb_rounded, isDark),
                _buildComingSoon('Notas', Icons.note_rounded, isDark),
                _buildComingSoon('Diário', Icons.book_rounded, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon(String feature, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.primary.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: AppColors.primary),
          ),
          SizedBox(height: 24),
          Text(
            '$feature em desenvolvimento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Em breve disponível',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(bool isDark, User? user) {
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.login_rounded, size: 64, color: AppColors.primary),
            ),
            SizedBox(height: 24),
            Text(
              'Faça login para ver suas metas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('goals')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                SizedBox(height: 16),
                Text(
                  'Erro ao carregar metas',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.track_changes_rounded,
                    size: 64,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Nenhuma meta ainda',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Toque no + para criar sua primeira meta',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final goals = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index].data() as Map<String, dynamic>;
            final goalId = goals[index].id;
            final title = goal['title'] ?? '';
            final description = goal['description'] ?? '';
            final category = goal['category'] ?? 'Outro';
            final target = (goal['target'] ?? 0).toDouble();
            final current = (goal['current'] ?? 0).toDouble();
            final completed = goal['completed'] ?? false;
            final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: target > 0 ? () => _updateProgress(goalId, current, target) : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
                    border: Border.all(
                      color: completed
                          ? AppColors.success.withOpacity(0.5)
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      width: completed ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(category).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getCategoryColor(category).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: _getCategoryColor(category),
                                size: 22,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : Colors.black,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ),
                                      if (completed)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: AppColors.success,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Completa',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(category).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _getCategoryColor(category),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_rounded, color: AppColors.error),
                              onPressed: () => _deleteGoal(goalId),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          SizedBox(height: 12),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (target > 0) ...[
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Progresso',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'R\$ ${current.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Meta',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'R\$ ${target.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    completed ? AppColors.success : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(progress * 100).toStringAsFixed(1)}% completo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (target > current)
                                Text(
                                  'Faltam R\$ ${(target - current).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
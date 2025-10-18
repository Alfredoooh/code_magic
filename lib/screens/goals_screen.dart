// lib/screens/goals_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_ui_components.dart';
import 'goals_widgets/goals_add_task_screen.dart';
import 'goals_widgets/goals_add_strategy_screen.dart';
import 'goals_widgets/goals_add_note_screen.dart';
import 'goals_widgets/goals_journal_screen.dart';
import 'goals_widgets/goals_checklist_screen.dart';
import 'goals_widgets/goals_pro_overlay.dart';
import 'plans_screen.dart';

class GoalsScreen extends StatefulWidget {
  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  String _selectedCategory = 'Financeiro';
  bool _isPro = false;
  bool _isAdmin = false;
  bool _isLoading = true;
  late TabController _tabController;

  final List<String> _categories = [
    'Financeiro',
    'Saúde',
    'Educação',
    'Carreira',
    'Pessoal',
    'Outro',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _isPro = doc.data()?['pro'] == true;
          _isAdmin = doc.data()?['admin'] == true;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showAddGoalModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context,
      height: MediaQuery.of(context).size.height * 0.85,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSectionTitle(text: 'Nova Meta', fontSize: 24),
                    IconButton(
                      icon: Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                AppFieldLabel(text: 'Título'),
                AppTextField(
                  controller: _titleController,
                  hintText: 'Ex: Economizar R\$ 10.000',
                ),
                SizedBox(height: 20),
                AppFieldLabel(text: 'Categoria'),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () {
                        setModalState(() => _selectedCategory = category);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : Color(0xFFF2F2F7)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : Colors.black),
                            fontWeight: FontWeight.w600,
                          ),
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
                ),
                SizedBox(height: 32),
                AppPrimaryButton(
                  text: 'Criar Meta',
                  onPressed: _saveGoal,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveGoal() async {
    if (_titleController.text.trim().isEmpty) {
      AppDialogs.showError(context, 'Erro', 'Por favor, insira um título');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('goals').add({
        'userId': user.uid,
        'title': _titleController.text.trim(),
        'category': _selectedCategory,
        'target': _targetController.text.isNotEmpty
            ? double.tryParse(_targetController.text) ?? 0
            : 0,
        'current': 0,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _targetController.clear();
      setState(() => _selectedCategory = 'Financeiro');

      Navigator.pop(context);

      AppDialogs.showSuccess(context, 'Sucesso', 'Meta criada com sucesso!');
    } catch (e) {
      AppDialogs.showError(context, 'Erro', 'Erro ao criar meta: $e');
    }
  }

  Future<void> _deleteGoal(String goalId) async {
    AppDialogs.showConfirmation(
      context,
      'Excluir Meta',
      'Tem certeza que deseja excluir esta meta?',
      onConfirm: () async {
        try {
          await FirebaseFirestore.instance.collection('goals').doc(goalId).delete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meta excluída'),
              backgroundColor: AppColors.primary,
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
    switch (category) {
      case 'Financeiro':
        return Icons.attach_money_rounded;
      case 'Saúde':
        return Icons.favorite_rounded;
      case 'Educação':
        return Icons.school_rounded;
      case 'Carreira':
        return Icons.work_rounded;
      case 'Pessoal':
        return Icons.person_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  void _showOptionsMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context,
      height: 450,
      child: Column(
        children: [
          SizedBox(height: 20),
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
                  builder: (context) => GoalsAddTaskScreen(),
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
                  builder: (context) => GoalsAddStrategyScreen(),
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
                  builder: (context) => GoalsAddNoteScreen(),
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
                  builder: (context) => GoalsJournalScreen(),
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
                  builder: (context) => GoalsChecklistScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
          ),
        ],
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
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    bool hasAccess = _isPro || _isAdmin;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          body: CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: isDark ? AppColors.darkBackground.withOpacity(0.9) : AppColors.lightBackground.withOpacity(0.9),
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground.withOpacity(0.75) : AppColors.lightBackground.withOpacity(0.75),
                      ),
                      child: FlexibleSpaceBar(
                        centerTitle: false,
                        titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                        title: Text(
                          'Metas',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: AppColors.primary),
                    onPressed: hasAccess ? _showAddGoalModal : null,
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white : Colors.black),
                    onPressed: hasAccess ? _showOptionsMenu : null,
                  ),
                ],
              ),
              if (hasAccess)
                SliverToBoxAdapter(
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(text: 'Metas'),
                      Tab(text: 'Tarefas'),
                      Tab(text: 'Estratégias'),
                      Tab(text: 'Notas'),
                      Tab(text: 'Diário'),
                    ],
                  ),
                ),
              if (hasAccess)
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGoalsList(isDark, user),
                      Center(child: Text('Tarefas em desenvolvimento')),
                      Center(child: Text('Estratégias em desenvolvimento')),
                      Center(child: Text('Notas em desenvolvimento')),
                      Center(child: Text('Diário em desenvolvimento')),
                    ],
                  ),
                )
              else
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.track_changes_rounded,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma meta ainda',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!hasAccess) GoalsProOverlay(),
      ],
    );
  }

  Widget _buildGoalsList(bool isDark, User? user) {
    if (user == null) {
      return Center(child: Text('Faça login para ver suas metas'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('goals')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.track_changes_rounded,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhuma meta ainda',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Toque no + para criar sua primeira meta',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
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
            final category = goal['category'] ?? 'Outro';
            final target = (goal['target'] ?? 0).toDouble();
            final current = (goal['current'] ?? 0).toDouble();
            final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

            return AppCard(
              padding: EdgeInsets.all(16),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_rounded, color: Colors.red),
                        onPressed: () => _deleteGoal(goalId),
                      ),
                    ],
                  ),
                  if (target > 0) ...[
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'R\$ ${current.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Text(
                          'R\$ ${target.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.darkBorder : Color(0xFFE5E5EA),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% completo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/category_icon.dart';
import 'task_detail_screen.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark ||
        (themeProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          _TasksTab(),
          _CategoriesTab(),
          _SettingsTab(),
        ],
      ),
      floatingActionButton: _selectedIndex < 2
          ? FloatingActionButton(
              onPressed: () => _openAddTask(context),
              child: const Icon(LucideIcons.plus, size: 24),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF2D2D3D)
                : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, LucideIcons.layout_dashboard, 'Início', isDark),
              _buildNavItem(context, 1, LucideIcons.square_check, 'Tarefas', isDark),
              _buildNavItem(context, 2, LucideIcons.grid_2x2, 'Categorias', isDark),
              _buildNavItem(context, 3, LucideIcons.settings, 'Definições', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedIndex == index;
    final selectedColor = const Color(0xFF6366F1);
    final unselectedColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF9CA3AF);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? selectedColor : unselectedColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
  }
}

// ─── Dashboard Tab ──────────────────────────────────────────────────────────

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TaskFlow',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => IconButton(
                icon: Icon(
                  themeProvider.isDark
                      ? LucideIcons.sun
                      : LucideIcons.moon,
                  size: 22,
                ),
                onPressed: themeProvider.toggleTheme,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Progress ring
              ProgressRing(
                completed: provider.completedTasks,
                total: provider.totalTasks,
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: StatsCard(
                      label: 'Pendentes',
                      value: provider.pendingTasks,
                      icon: LucideIcons.clock,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      label: 'Concluídas',
                      value: provider.completedTasks,
                      icon: LucideIcons.circle_check,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      label: 'Atrasadas',
                      value: provider.overdueTasks.length,
                      icon: LucideIcons.circle_alert,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Today's tasks
              if (provider.todayTasks.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Para Hoje',
                  count: provider.todayTasks.length,
                  icon: LucideIcons.calendar_check,
                ),
                const SizedBox(height: 12),
                ...provider.todayTasks.map(
                  (task) => TaskCard(
                    task: task,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(task: task),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Overdue tasks
              if (provider.overdueTasks.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Atrasadas',
                  count: provider.overdueTasks.length,
                  icon: LucideIcons.triangle_alert,
                  color: const Color(0xFFEF4444),
                ),
                const SizedBox(height: 12),
                ...provider.overdueTasks.map(
                  (task) => TaskCard(
                    task: task,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(task: task),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Recent tasks
              _SectionHeader(
                title: 'Tarefas Recentes',
                count: provider.tasks.length,
                icon: LucideIcons.list,
              ),
              const SizedBox(height: 12),
              if (provider.tasks.isEmpty)
                _EmptyState(
                  icon: LucideIcons.clipboard_list,
                  title: 'Sem tarefas',
                  subtitle: 'Toque no + para adicionar a sua primeira tarefa',
                )
              else
                ...provider.tasks.take(5).map(
                      (task) => TaskCard(
                        task: task,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(task: task),
                          ),
                        ),
                      ),
                    ),
            ]),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia!';
    if (hour < 18) return 'Boa tarde!';
    return 'Boa noite!';
  }
}

// ─── Tasks Tab ───────────────────────────────────────────────────────────────

class _TasksTab extends StatefulWidget {
  const _TasksTab();

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          title: const Text('Tarefas'),
          actions: [
            IconButton(
              icon: Icon(
                provider.showCompleted
                    ? LucideIcons.eye
                    : LucideIcons.eye_off,
                size: 20,
              ),
              onPressed: provider.toggleShowCompleted,
              tooltip: provider.showCompleted
                  ? 'Ocultar concluídas'
                  : 'Mostrar concluídas',
            ),
            if (provider.filterCategory != null ||
                provider.filterPriority != null)
              IconButton(
                icon: const Icon(LucideIcons.funnel_x),
                onPressed: provider.clearFilters,
                tooltip: 'Limpar filtros',
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: provider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar tarefas...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter chips
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'Alta',
                          isSelected:
                              provider.filterPriority == TaskPriority.high,
                          color: const Color(0xFFEF4444),
                          onTap: () => provider.setFilterPriority(
                            provider.filterPriority == TaskPriority.high
                                ? null
                                : TaskPriority.high,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Média',
                          isSelected:
                              provider.filterPriority == TaskPriority.medium,
                          color: const Color(0xFFF59E0B),
                          onTap: () => provider.setFilterPriority(
                            provider.filterPriority == TaskPriority.medium
                                ? null
                                : TaskPriority.medium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Baixa',
                          isSelected:
                              provider.filterPriority == TaskPriority.low,
                          color: const Color(0xFF10B981),
                          onTap: () => provider.setFilterPriority(
                            provider.filterPriority == TaskPriority.low
                                ? null
                                : TaskPriority.low,
                          ),
                        ),
                        const SizedBox(width: 16),
                        ...TaskCategory.values.map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                label: cat.label,
                                isSelected:
                                    provider.filterCategory == cat,
                                color: cat.color,
                                onTap: () => provider.setFilterCategory(
                                  provider.filterCategory == cat
                                      ? null
                                      : cat,
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: provider.tasks.isEmpty
              ? SliverFillRemaining(
                  child: _EmptyState(
                    icon: LucideIcons.clipboard_list,
                    title: 'Sem tarefas',
                    subtitle: provider.searchQuery.isNotEmpty
                        ? 'Nenhuma tarefa encontrada para "${provider.searchQuery}"'
                        : 'Toque no + para adicionar a sua primeira tarefa',
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = provider.tasks[index];
                      return TaskCard(
                        task: task,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(task: task),
                          ),
                        ),
                      );
                    },
                    childCount: provider.tasks.length,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── Categories Tab ──────────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final byCategory = provider.tasksByCategory;

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          snap: true,
          title: Text('Categorias'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = TaskCategory.values[index];
                final count = byCategory[category] ?? 0;
                final completedCount = provider.allTasks
                    .where((t) =>
                        t.category == category && t.isCompleted)
                    .length;

                return GestureDetector(
                  onTap: () => _openCategoryTasks(context, category),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF22222F)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2D2D3D)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CategoryIcon(
                            category: category, size: 20),
                        const Spacer(),
                        Text(
                          category.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count ${count == 1 ? 'tarefa' : 'tarefas'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        if (count > 0) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: count > 0
                                  ? completedCount / count
                                  : 0,
                              minHeight: 4,
                              backgroundColor: isDark
                                  ? const Color(0xFF2D2D3D)
                                  : const Color(0xFFE5E7EB),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  category.color),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              childCount: TaskCategory.values.length,
            ),
          ),
        ),
      ],
    );
  }

  void _openCategoryTasks(BuildContext context, TaskCategory category) {
    context.read<TaskProvider>().setFilterCategory(category);
    // Navigate to tasks tab would be handled by parent
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryTasksScreen(category: category),
      ),
    );
  }
}

class _CategoryTasksScreen extends StatelessWidget {
  final TaskCategory category;

  const _CategoryTasksScreen({required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final tasks = provider.allTasks
        .where((t) => t.category == category)
        .toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.priority.index.compareTo(a.priority.index);
      });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CategoryIcon(category: category, size: 18),
            const SizedBox(width: 10),
            Text(category.label),
          ],
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: tasks.isEmpty
          ? _EmptyState(
              icon: LucideIcons.clipboard_list,
              title: 'Sem tarefas',
              subtitle: 'Nenhuma tarefa nesta categoria',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  task: task,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(task: task),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTaskScreen(defaultCategory: category),
          ),
        ),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

// ─── Settings Tab ────────────────────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          floating: true,
          snap: true,
          title: Text('Definições'),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SettingsSection(
                title: 'Aparência',
                children: [
                  _SettingsTile(
                    icon: LucideIcons.palette,
                    title: 'Tema',
                    subtitle: _getThemeLabel(themeProvider.themeMode),
                    trailing: _ThemeSelector(
                      currentMode: themeProvider.themeMode,
                      onChanged: themeProvider.setThemeMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsSection(
                title: 'Sobre',
                children: [
                  _SettingsTile(
                    icon: LucideIcons.info,
                    title: 'Versão',
                    subtitle: '1.0.0',
                  ),
                  _SettingsTile(
                    icon: LucideIcons.code,
                    title: 'Desenvolvido com',
                    subtitle: 'Flutter + Lucide Icons',
                  ),
                  _SettingsTile(
                    icon: LucideIcons.heart,
                    title: 'TaskFlow',
                    subtitle: 'Gestor de tarefas moderno e minimalista',
                  ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }
}

class _ThemeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) onChanged;

  const _ThemeSelector({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(LucideIcons.sun, size: 16),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(LucideIcons.monitor, size: 16),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(LucideIcons.moon, size: 16),
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (modes) => onChanged(modes.first),
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF6B7280),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF22222F) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2D2D3D)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < children.length - 1)
                          Divider(
                            height: 1,
                            indent: 56,
                            color: isDark
                                ? const Color(0xFF2D2D3D)
                                : const Color(0xFFE5E7EB),
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF111827),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color? color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? const Color(0xFF6366F1);

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark
                ? const Color(0xFFF1F5F9)
                : const Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xFF6366F1).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : (isDark ? const Color(0xFF22222F) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : (isDark ? const Color(0xFF2D2D3D) : const Color(0xFFE5E7EB)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? color
                : (isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }
}

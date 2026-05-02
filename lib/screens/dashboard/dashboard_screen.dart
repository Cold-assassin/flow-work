import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _svc = SupabaseService();
  Map<String, dynamic>? _stats;
  List<Task> _overdueTasks = [];
  List<Task> _myTasks = [];
  List<Project> _projects = [];
  bool _isloading = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isloading = true);

    try {
      print("STEP 1: Stats");
      final stats = await _svc.getDashboardStats();

      print("STEP 2: Overdue");
      final overdue = await _svc.getOverdueTasks();

      print("STEP 3: MyTasks");
      final myTasks = await _svc.getMyTasks();

      print("STEP 4: Projects");
      final projects = await _svc.getMyProjects();

      print("STEP 5: Profile");
      final profile = await _svc.getProfile(_svc.currentUserId!);

      print("ALL DATA FETCHED");

      setState(() {
        _stats = stats;
        _overdueTasks = overdue;
        _myTasks = myTasks.take(5).toList();
        _projects = projects.take(4).toList();
        _profile = profile;
        _isloading = false;
      });

    } catch (e, stack) {
      print("ERROR IN DASHBOARD: $e");
      print(stack);

      setState(() => _isloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good ${_greeting()}, ${_profile?.fullName.split(' ').first ?? ''}! ',
                style: const TextStyle(fontSize: 18)),
            const Text("Here's your overview", style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceMuted)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          const SizedBox(width: 8),
        ],
      ),
      body: _isloading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsRow(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTaskStatusChart()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildOverdueSection()),
                ],
              ),
              const SizedBox(height: 24),
              _buildMyTasksSection(),
              const SizedBox(height: 24),
              _buildProjectsSection(),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildStatsRow() {
    if (_stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final items = [
      {'label': 'Projects', 'value': _stats!['total_projects'], 'icon': Icons.folder_outlined, 'color': AppTheme.first},
      {'label': 'My Tasks', 'value': _stats!['my_tasks'], 'icon': Icons.task_outlined, 'color': AppTheme.accent},
      {'label': 'Completed', 'value': _stats!['completed_tasks'], 'icon': Icons.check_circle_outline, 'color': AppTheme.success},
      {'label': 'Overdue', 'value': _stats!['overdue_tasks'], 'icon': Icons.warning_amber_outlined, 'color': AppTheme.danger},
    ];

    return GridView.builder(
      key: ValueKey(_stats.toString()),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final color = item['color'] as Color;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(item['icon'] as IconData, color: color),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${item['value']}',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(item['label'] as String),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildTaskStatusChart() {
    final myTasks = _stats?['my_tasks'] ?? 0;
    final completed = _stats?['completed_tasks'] ?? 0;
    final inProgress = myTasks - completed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Progress', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: myTasks == 0
                ? const Center(child: Text('No tasks yet', style: TextStyle(color: AppTheme.onSurfaceMuted)))
                : PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    value: completed.toDouble(),
                    color: AppTheme.success,
                    title: '$completed',
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  PieChartSectionData(
                    value: inProgress.toDouble(),
                    color: AppTheme.accent,
                    title: '$inProgress',
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppTheme.success, 'Done'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.accent, 'Pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
    ]);
  }

  Widget _buildOverdueSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 18),
              const SizedBox(width: 8),
              Text('Overdue', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          if (_overdueTasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('🎉 No overdue tasks!', style: TextStyle(color: AppTheme.onSurfaceMuted)),
              ),
            )
          else
            ..._overdueTasks.take(5).map((task) => _overdueItem(task)),
        ],
      ),
    );
  }

  Widget _overdueItem(Task task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.danger,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  if (task.dueDate != null)
                    Text('Due ${_formatDate(task.dueDate!)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.danger)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Tasks', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: () {}, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 12),
        if (_myTasks.isEmpty)
          _emptyState('No tasks assigned to you')
        else
          ..._myTasks.map((task) => TaskCard(task: task, onTap: () => context.push('/tasks/${task.id}'))),
      ],
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Projects', style: Theme.of(context).textTheme.titleLarge),
            TextButton(onPressed: () => context.go('/projects'), child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 12),
        if (_projects.isEmpty)
          _emptyState('No projects yet')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: _projects.length,
            itemBuilder: (_, i) => _projectCard(_projects[i]),
          ),
      ],
    );
  }

  Widget _projectCard(Project project) {
    final color = _hexColor(project.color);
    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(project.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${project.totalTasks ?? 0} tasks',
                style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
            const Spacer(),
            LinearProgressIndicator(
              value: project.progress,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text('${(project.progress * 100).toInt()}% complete',
                style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(msg, style: const TextStyle(color: AppTheme.onSurfaceMuted)),
      ),
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppTheme.first;
    }
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}
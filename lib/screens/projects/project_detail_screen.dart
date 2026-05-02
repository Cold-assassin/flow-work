import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/task_card.dart';
import 'package:taskflow/widgets/create_task_dialog.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  final _svc = SupabaseService();
  Project? _project;
  List<Task> _tasks = [];
  List<ProjectMember> _members = [];
  bool _isloading = true;
  String? _userRole;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isloading = true);
    try {
      final results = await Future.wait([
        _svc.getProjectTasks(widget.projectId),
        _svc.getProjectMembers(widget.projectId),
        _svc.getUserRole(widget.projectId),
        _svc.getMyProjects(),
      ]);
      final projects = results[3] as List<Project>;
      final project = projects.where((p) => p.id == widget.projectId).firstOrNull;

      setState(() {
        _tasks = results[0] as List<Task>;
        _members = results[1] as List<ProjectMember>;
        _userRole = results[2] as String?;
        _project = project;
        _isloading = false;
      });
    } catch (_) {
      setState(() => _isloading = false);
    }
  }

  List<Task> _tasksByStatus(String status) =>
      _tasks.where((t) => t.status == status).toList();

  bool get _isAdmin => _userRole == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_project?.name ?? 'Project'),
            if (_userRole != null)
              Text(_isAdmin ? 'Admin' : 'Member',
                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
          ],
        ),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.group_outlined),
              onPressed: () => context.push('/projects/${widget.projectId}/members').then((_) => _load()),
            ),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              if (_isAdmin)
                const PopupMenuItem(value: 'archive', child: Text('Archive Project')),
            ],
            onSelected: (val) {
              if (val == 'refresh') _load();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: TaskStatus.all.map((s) {
            final count = _tasksByStatus(s).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(TaskStatus.label(s)),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.statusColor(s).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count',
                          style: TextStyle(fontSize: 11, color: AppTheme.statusColor(s), fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTask,
        backgroundColor: AppTheme.first,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: _isloading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          if (_project != null) _buildProjectHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: TaskStatus.all
                  .map((s) => _buildTaskList(_tasksByStatus(s), s))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    final project = _project!;
    final color = _hexColor(project.color);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (project.description != null)
                  Text(project.description!,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceMuted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _infoBadge(Icons.task_outlined, '${project.totalTasks ?? 0}', AppTheme.onSurfaceMuted),
                    const SizedBox(width: 8),
                    _infoBadge(Icons.check_circle_outline, '${project.completedTasks ?? 0}', AppTheme.success),
                    if ((project.overdueTasks ?? 0) > 0) ...[
                      const SizedBox(width: 8),
                      _infoBadge(Icons.warning_amber_outlined, '${project.overdueTasks}', AppTheme.danger),
                    ],
                    const SizedBox(width: 8),
                    _infoBadge(Icons.group_outlined, '${project.memberCount ?? 0}', AppTheme.onSurfaceMuted),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Text('${(project.progress * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: project.progress,
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _buildTaskList(List<Task> tasks, String status) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.statusColor(status).withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('No ${TaskStatus.label(status)} tasks',
                style: const TextStyle(color: AppTheme.onSurfaceMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (_, i) => TaskCard(
          task: tasks[i],
          members: _members,
          canEdit: _isAdmin || tasks[i].assigneeId == _svc.currentUserId,
          onTap: () => context.push('/tasks/${tasks[i].id}').then((_) => _load()),
          onStatusChange: (newStatus) async {
            await _svc.updateTask(tasks[i].id, {'status': newStatus});
            _load();
          },
          onDelete: _isAdmin || tasks[i].createdBy == _svc.currentUserId
              ? () async {
            final confirm = await _showDeleteConfirm();
            if (confirm == true) {
              await _svc.deleteTask(tasks[i].id);
              _load();
            }
          }
              : null,
        ),
      ),
    );
  }

  void _showCreateTask() {
    showDialog(
      context: context,
      builder: (_) => CreateTaskDialog(
        projectId: widget.projectId,
        members: _members,
        onCreated: (_) => _load(),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm() {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Delete'),
          ),
        ],
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
}
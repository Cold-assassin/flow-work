import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _svc = SupabaseService();
  List<Project> _projects = [];
  bool _isloading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isloading = true);
    try {
      final projects = await _svc.getMyProjects();
      setState(() { _projects = projects; _isloading = false; });
    } catch (_) {
      setState(() => _isloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/projects/create').then((_) => _load()),
        backgroundColor: AppTheme.first,
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      body: _isloading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: _projects.isEmpty
            ? _buildEmpty()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _projects.length,
          itemBuilder: (_, i) => _buildProjectCard(_projects[i]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 64, color: AppTheme.onSurfaceMuted),
          const SizedBox(height: 16),
          const Text('No projects yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Create your first project to get started', style: TextStyle(color: AppTheme.onSurfaceMuted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/projects/create').then((_) => _load()),
            icon: const Icon(Icons.add),
            label: const Text('Create Project'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final color = _hexColor(project.color);
    return GestureDetector(
      onTap: () => context.push('/projects/${project.id}').then((_) => _load()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(project.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                if (project.isAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.first.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Admin', style: TextStyle(fontSize: 11, color: AppTheme.first, fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(project.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(project.status,
                      style: TextStyle(fontSize: 11, color: _statusColor(project.status), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            if (project.description != null) ...[
              const SizedBox(height: 8),
              Text(project.description!,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 14)),
            ],
            const SizedBox(height: 16),
            // Stats row
            Row(
              children: [
                _stat(Icons.task_outlined, '${project.totalTasks ?? 0} tasks', AppTheme.onSurfaceMuted),
                const SizedBox(width: 16),
                _stat(Icons.group_outlined, '${project.memberCount ?? 0} members', AppTheme.onSurfaceMuted),
                if ((project.overdueTasks ?? 0) > 0) ...[
                  const SizedBox(width: 16),
                  _stat(Icons.warning_amber_outlined, '${project.overdueTasks} overdue', AppTheme.danger),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.progress,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(project.progress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppTheme.first;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return AppTheme.success;
      case 'archived': return AppTheme.onSurfaceMuted;
      case 'completed': return AppTheme.first;
      default: return AppTheme.onSurfaceMuted;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _svc = SupabaseService();
  Task? _task;
  List<TaskComment> _comments = [];
  List<ProjectMember> _members = [];
  bool _isloading = true;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {

    setState(() => _isloading = true);
    try {
      final myTasks = await _svc.getMyTasks();

      Task? task = myTasks.where((t) => t.id == widget.taskId).firstOrNull;

      if (task != null) {
        final results = await Future.wait([
          _svc.getTaskComments(task.id),
          _svc.getProjectMembers(task.projectId),
        ]);
        setState(() {
          _task = task;
          _comments = results[0] as List<TaskComment>;
          _members = results[1] as List<ProjectMember>;
          _isloading = false;
        });
      } else {
        setState(() => _isloading = false);
      }
    } catch (_) {
      setState(() => _isloading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    if (_task == null) return;
    final updated = await _svc.updateTask(_task!.id, {'status': status});
    setState(() => _task = updated);
  }

  Future<void> _addComment() async {
    if (_task == null || _commentCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final comment = await _svc.addComment(
        taskId: _task!.id,
        content: _commentCtrl.text.trim(),
      );
      setState(() {
        _comments.add(comment);
        _commentCtrl.clear();
      });
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (_task != null)
            PopupMenuButton<String>(
              onSelected: (status) => _updateStatus(status),
              itemBuilder: (_) => TaskStatus.all
                  .map((s) => PopupMenuItem(value: s, child: Text(TaskStatus.label(s))))
                  .toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _task != null ? _statusBadge(_task!.status) : const SizedBox(),
              ),
            ),
        ],
      ),
      body: _isloading
          ? const Center(child: CircularProgressIndicator())
          : _task == null
          ? const Center(child: Text('Task not found'))
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final task = _task!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(task.title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              _priorityBadge(task.priority),
            ],
          ),
          const SizedBox(height: 16),


          _buildMetaGrid(task),
          const SizedBox(height: 20),


          if (task.description != null && task.description!.isNotEmpty) ...[
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(task.description!, style: const TextStyle(height: 1.6)),
            ),
            const SizedBox(height: 20),
          ],


          if (task.tags.isNotEmpty) ...[
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: task.tags.map((tag) => Chip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                backgroundColor: AppTheme.first.withOpacity(0.1),
                side: BorderSide(color: AppTheme.first.withOpacity(0.3)),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],


          Row(
            children: TaskStatus.all.map((s) {
              final active = task.status == s;
              final color = AppTheme.statusColor(s);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: active ? null : () => _updateStatus(s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? color : color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(active ? 1 : 0.3)),
                      ),
                      child: Text(
                        TaskStatus.label(s),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : color,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Comments
          Row(
            children: [
              const Text('Comments', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_comments.length}', style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._comments.map((c) => _buildComment(c)),
          const SizedBox(height: 12),
          // Add comment
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _submitting ? null : _addComment,
                icon: _submitting
                    ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send, color: AppTheme.first),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaGrid(Task task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _metaRow(Icons.person_outline, 'Assignee',
              task.assignee?.fullName ?? 'Unassigned'),
          const Divider(height: 16, color: Colors.white12),
          _metaRow(Icons.calendar_today_outlined, 'Due Date',
              task.dueDate != null
                  ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                  : 'No date',
              valueColor: task.isOverdue ? AppTheme.danger : null),
          const Divider(height: 16, color: Colors.white12),
          _metaRow(Icons.person_outlined, 'Created by',
              task.creator?.fullName ?? 'Unknown'),
          const Divider(height: 16, color: Colors.white12),
          _metaRow(Icons.access_time_outlined, 'Created',
              timeago.format(task.createdAt)),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontSize: 13, color: AppTheme.onSurfaceMuted)),
        const SizedBox(width: 8),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppTheme.onSurface)),
      ],
    );
  }

  Widget _buildComment(TaskComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.first.withOpacity(0.2),
            child: Text(comment.user?.initials ?? '?',
                style: const TextStyle(fontSize: 12, color: AppTheme.first, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(comment.user?.fullName ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(timeago.format(comment.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.content, style: const TextStyle(fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(TaskStatus.label(status),
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(width: 4),
          Icon(Icons.expand_more, color: color, size: 14),
        ],
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final color = AppTheme.priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(priority.toUpperCase(),
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}
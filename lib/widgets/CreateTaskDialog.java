import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class CreateTaskDialog extends StatefulWidget {
  final String projectId;
  final List<ProjectMember> members;
  final void Function(Task) onCreated;

  const CreateTaskDialog({
    super.key,
    required this.projectId,
    required this.members,
    required this.onCreated,
  });

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _status = TaskStatus.todo;
  String _priority = TaskPriority.medium;
  String? _assigneeId;
  DateTime? _dueDate;
  bool _isloading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isloading = true);
    try {
      final task = await SupabaseService().createTask(
        projectId: widget.projectId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        status: _status,
        priority: _priority,
        assigneeId: _assigneeId,
        dueDate: _dueDate,
      );
      widget.onCreated(task);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('New Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Task Title *'),
                validator: (v) => v?.isNotEmpty == true ? null : 'Required',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: 'Priority'),
                      items: TaskPriority.all.map((p) {
                        final color = AppTheme.priorityColor(p);
                        return DropdownMenuItem(
                          value: p,
                          child: Row(children: [
                            Container(width: 8, height: 8,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(p[0].toUpperCase() + p.substring(1)),
                          ]),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: TaskStatus.all.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(TaskStatus.label(s)),
                      )).toList(),
                      onChanged: (v) => setState(() => _status = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _assigneeId,
                decoration: const InputDecoration(
                  labelText: 'Assign to',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Unassigned')),
                  ...widget.members.map((m) => DropdownMenuItem(
                    value: m.userId,
                    child: Text(m.profile?.fullName ?? m.userId),
                  )),
                ],
                onChanged: (v) => setState(() => _assigneeId = v),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 3)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.onSurfaceMuted),
                      const SizedBox(width: 10),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Set due date',
                        style: TextStyle(
                          color: _dueDate != null ? AppTheme.onSurface : AppTheme.onSurfaceMuted,
                        ),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.close, size: 14),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isloading ? null : _submit,
                  icon: _isloading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add),
                  label: const Text('Create Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
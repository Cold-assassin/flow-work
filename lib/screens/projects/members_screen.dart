import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';

class MembersScreen extends StatefulWidget {
  final String projectId;
  const MembersScreen({super.key, required this.projectId});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _svc = SupabaseService();
  List<ProjectMember> _members = [];
  bool _isloading = true;
  String? _myRole;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isloading = true);
    final results = await Future.wait([
      _svc.getProjectMembers(widget.projectId),
      _svc.getUserRole(widget.projectId),
    ]);
    setState(() {
      _members = results[0] as List<ProjectMember>;
      _myRole = results[1] as String?;
      _isloading = false;
    });
  }

  bool get _isAdmin => _myRole == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Members (${_members.length})'),
        actions: [
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: _showAddMember,
            ),
        ],
      ),
      body: _isloading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _members.length,
        itemBuilder: (_, i) => _buildMemberCard(_members[i]),
      ),
    );
  }

  Widget _buildMemberCard(ProjectMember member) {
    final isMe = member.userId == _svc.currentUserId;
    final profile = member.profile;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.first.withOpacity(0.2),
            child: Text(profile?.initials ?? '?',
                style: const TextStyle(color: AppTheme.first, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(profile?.fullName ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('You', style: TextStyle(fontSize: 10, color: AppTheme.accent)),
                      ),
                    ],
                  ],
                ),
                Text(profile?.email ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: member.isAdmin ? AppTheme.first.withOpacity(0.15) : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              member.isAdmin ? 'Admin' : 'Member',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: member.isAdmin ? AppTheme.first : AppTheme.onSurfaceMuted,
              ),
            ),
          ),
          if (_isAdmin && !isMe) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (val) => _handleMemberAction(val, member),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle_role',
                  child: Text(member.isAdmin ? 'Set as Member' : 'Set as Admin'),
                ),
                const PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: AppTheme.danger))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleMemberAction(String action, ProjectMember member) async {
    if (action == 'toggle_role') {
      final newRole = member.isAdmin ? 'member' : 'admin';
      await _svc.updateMemberRole(
        projectId: widget.projectId,
        userId: member.userId,
        role: newRole,
      );
      _load();
    } else if (action == 'remove') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Remove Member'),
          content: Text('Remove ${member.profile?.fullName} from this project?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _svc.removeMember(projectId: widget.projectId, userId: member.userId);
        _load();
      }
    }
  }

  void _showAddMember() {
    showDialog(
      context: context,
      builder: (_) => _AddMemberDialog(
        projectId: widget.projectId,
        existingMemberIds: _members.map((m) => m.userId).toList(),
        onAdded: _load,
      ),
    );
  }
}

class _AddMemberDialog extends StatefulWidget {
  final String projectId;
  final List<String> existingMemberIds;
  final VoidCallback onAdded;

  const _AddMemberDialog({
    required this.projectId,
    required this.existingMemberIds,
    required this.onAdded,
  });

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _svc = SupabaseService();
  final _searchCtrl = TextEditingController();
  List<UserProfile> _results = [];
  bool _searching = false;
  String _role = 'member';

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _results = []); return; }
    setState(() => _searching = true);
    final results = await _svc.searchUsers(q);
    setState(() {
      _results = results.where((u) => !widget.existingMemberIds.contains(u.id)).toList();
      _searching = false;
    });
  }

  Future<void> _add(UserProfile user) async {
    await _svc.addMember(
      projectId: widget.projectId,
      userId: user.id,
      role: _role,
    );
    widget.onAdded();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'member', child: Text('Member')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 12),
            if (_searching)
              const Center(child: CircularProgressIndicator())
            else if (_results.isEmpty && _searchCtrl.text.length >= 2)
              const Text('No users found', style: TextStyle(color: AppTheme.onSurfaceMuted))
            else
              ..._results.map((user) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.first.withOpacity(0.2),
                  child: Text(user.initials, style: const TextStyle(color: AppTheme.first)),
                ),
                title: Text(user.fullName),
                subtitle: Text(user.email),
                trailing: ElevatedButton(
                  onPressed: () => _add(user),
                  child: const Text('Add'),
                ),
              )),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
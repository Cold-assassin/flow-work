import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../utils/theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});
  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _svc = SupabaseService();
  String? _name;
  String? _email;

  @override
  void initState() {
    super.initState();
    final user = _svc.currentUser;
    _email = user?.email;
    _svc.getProfile(_svc.currentUserId!).then((p) {
      if (mounted) setState(() => _name = p?.fullName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.first.withOpacity(0.3), AppTheme.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.first,
                  child: Text(
                    _name?.isNotEmpty == true ? _name![0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_name ?? 'Loading...', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(_email ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _navItem(context, Icons.dashboard_outlined, 'Dashboard', '/dashboard', location),
                _navItem(context, Icons.folder_outlined, 'Projects', '/projects', location),
                const Divider(height: 24, color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.danger),
                  title: const Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
                  onTap: () async {
                    await _svc.signOut();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.first,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                const Text('TaskFlow', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, String route, String current) {
    final active = current.startsWith(route);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? AppTheme.first.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: active ? AppTheme.first : AppTheme.onSurfaceMuted, size: 22),
        title: Text(label,
            style: TextStyle(
              color: active ? AppTheme.first : AppTheme.onSurface,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            )),
        onTap: () {
          Navigator.pop(context);
          context.go(route);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
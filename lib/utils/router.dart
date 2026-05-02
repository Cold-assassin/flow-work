import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/projects/projects_screen.dart';
import '../screens/projects/project_detail_screen.dart';
import '../screens/projects/create_project_screen.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/projects/members_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  redirect: (context, state) {
    final user = Supabase.instance.client.auth.currentUser;
    final isAuth = user != null;
    final isOnAuth = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

    if (!isAuth && !isOnAuth) return '/login';
    if (isAuth && isOnAuth) return '/dashboard';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/projects', builder: (_, __) => const ProjectsScreen()),
    GoRoute(
      path: '/projects/create',
      builder: (_, __) => const CreateProjectScreen(),
    ),
    GoRoute(
      path: '/projects/:id',
      builder: (_, state) => ProjectDetailScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/members',
      builder: (_, state) => MembersScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/tasks/:id',
      builder: (_, state) => TaskDetailScreen(taskId: state.pathParameters['id']!),
    ),
  ],
);
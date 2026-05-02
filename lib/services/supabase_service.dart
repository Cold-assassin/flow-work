import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  String? get currentUserId => currentUser?.id;

 //authencaton

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // profile

  Future<UserProfile?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response != null ? UserProfile.fromJson(response) : null;
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    await client.from('profiles').update(updates).eq('id', currentUserId!);
  }

  Future<List<UserProfile>> searchUsers(String query) async {
    final response = await client
        .from('profiles')
        .select()
        .or('email.ilike.%$query%,full_name.ilike.%$query%')
        .neq('id', currentUserId!)
        .limit(10);
    return response.map((e) => UserProfile.fromJson(e)).toList();
  }

  // project

  Future<List<Project>> getMyProjects() async {
    final response = await client
        .from('project_members')
        .select('''
          role,
          projects (
            id, name, description, color, status, owner_id, due_date, created_at, updated_at
          )
        ''')
        .eq('user_id', currentUserId!);

    // Count stats separately
    final List<Project> projects = [];
    for (final row in response) {
      final projectData = row['projects'] as Map<String, dynamic>;
      final projectId = projectData['id'];

      // Get task counts
      final tasks = await client
          .from('tasks')
          .select('status, due_date')
          .eq('project_id', projectId);

      final total = tasks.length;
      final completed = tasks
          .where((t) => t['status'] == 'done')
          .length;
      final overdue = tasks.where((t) {
        final due = t['due_date'];
        return due != null &&
            DateTime.parse(due).isBefore(DateTime.now()) &&
            t['status'] != 'done';
      }).length;

      final memberCount = await client
          .from('project_members')
          .select('id')
          .eq('project_id', projectId);

      projects.add(Project(
        id: projectData['id'],
        name: projectData['name'],
        description: projectData['description'],
        color: projectData['color'] ?? '#6366f1',
        status: projectData['status'] ?? 'active',
        ownerId: projectData['owner_id'],
        dueDate: projectData['due_date'] != null
            ? DateTime.parse(projectData['due_date'])
            : null,
        createdAt: DateTime.parse(projectData['created_at']),
        updatedAt: DateTime.parse(projectData['updated_at']),
        memberCount: memberCount.length,
        totalTasks: total,
        completedTasks: completed,
        overdueTasks: overdue,
        userRole: row['role'],
      ));
    }
    return projects;
  }

  Future<Project> createProject({
    required String name,
    String? description,
    String color = '#6366f1',
    DateTime? dueDate,
  }) async {
    final response = await client.from('projects').insert({
      'name': name,
      'description': description,
      'color': color,
      'owner_id': currentUserId,
      'due_date': dueDate?.toIso8601String(),
    }).select().single();
    return Project.fromJson(response);
  }

  Future<void> updateProject(String projectId,
      Map<String, dynamic> updates) async {
    await client.from('projects').update(updates).eq('id', projectId);
  }

  Future<void> deleteProject(String projectId) async {
    await client.from('projects').delete().eq('id', projectId);
  }

  // project memeber

  Future<List<ProjectMember>> getProjectMembers(String projectId) async {
    final response = await client
        .from('project_members')
        .select('*, profiles(*)')
        .eq('project_id', projectId);
    return response.map((e) => ProjectMember.fromJson(e)).toList();
  }

  Future<void> addMember({
    required String projectId,
    required String userId,
    String role = 'member',
  }) async {
    await client.from('project_members').insert({
      'project_id': projectId,
      'user_id': userId,
      'role': role,
    });
  }

  Future<void> updateMemberRole({
    required String projectId,
    required String userId,
    required String role,
  }) async {
    await client.from('project_members')
        .update({'role': role})
        .eq('project_id', projectId)
        .eq('user_id', userId);
  }

  Future<void> removeMember({
    required String projectId,
    required String userId,
  }) async {
    await client.from('project_members')
        .delete()
        .eq('project_id', projectId)
        .eq('user_id', userId);
  }

  Future<String?> getUserRole(String projectId) async {
    final response = await client
        .from('project_members')
        .select('role')
        .eq('project_id', projectId)
        .eq('user_id', currentUserId!)
        .maybeSingle();
    return response?['role'];
  }

  // task

  Future<List<Task>> getProjectTasks(String projectId, {String? status}) async {
    var query = client
        .from('tasks')
        .select(
        '*, assignee:assignee_id(id,email,full_name,avatar_url), creator:created_by(id,email,full_name)')
        .eq('project_id', projectId);

    if (status != null) query = query.eq('status', status);

    final response = await query.order('created_at', ascending: false);
    return response.map((e) => Task.fromJson(e)).toList();
  }

  Future<List<Task>> getMyTasks() async {
    print("fetching my task");
    final response = await client
        .from('tasks')
        .select(
        '*, assignee:assignee_id(id,email,full_name,avatar_url), creator:created_by(id,email,full_name)')
        .eq('assignee_id', currentUserId!)
        .order('due_date', ascending: true);
    print("RAW TASK DATA: $response");
    return response.map((e) => Task.fromJson(e)).toList();
  }

  Future<List<Task>> getOverdueTasks() async {
    // Get all project IDs the user is member of
    final memberProjects = await client
        .from('project_members')
        .select('project_id')
        .eq('user_id', currentUserId!);

    if (memberProjects.isEmpty) return [];

    final projectIds = memberProjects.map((e) => e['project_id'] as String)
        .toList();

    final response = await client
        .from('tasks')
        .select('*, assignee:assignee_id(id,email,full_name,avatar_url)')
        .inFilter('project_id', projectIds)
        .lt('due_date', DateTime.now().toIso8601String())
        .neq('status', 'done')
        .order('due_date', ascending: true)
        .limit(10);

    return response.map((e) => Task.fromJson(e)).toList();
  }

  Future<Task> createTask({
    required String projectId,
    required String title,
    String? description,
    String status = 'todo',
    String priority = 'medium',
    String? assigneeId,
    DateTime? dueDate,
    List<String> tags = const [],
  }) async {
    final response = await client.from('tasks').insert({
      'project_id': projectId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assignee_id': assigneeId,
      'created_by': currentUserId,
      'due_date': dueDate?.toIso8601String(),
      'tags': tags,
    })
        .select(
        '*, assignee:assignee_id(id,email,full_name,avatar_url), creator:created_by(id,email,full_name)')
        .single();
    return Task.fromJson(response);
  }

  Future<Task> updateTask(String taskId, Map<String, dynamic> updates) async {
    final response = await client.from('tasks')
        .update(updates)
        .eq('id', taskId)
        .select(
        '*, assignee:assignee_id(id,email,full_name,avatar_url), creator:created_by(id,email,full_name)')
        .single();
    return Task.fromJson(response);
  }

  Future<void> deleteTask(String taskId) async {
    await client.from('tasks').delete().eq('id', taskId);
  }





  Future<List<TaskComment>> getTaskComments(String taskId) async {
    final response = await client
        .from('task_comments')
        .select('*, profiles(*)')
        .eq('task_id', taskId)
        .order('created_at');
    return response.map((e) => TaskComment.fromJson(e)).toList();
  }

  Future<TaskComment> addComment({
    required String taskId,
    required String content,
  }) async {
    final response = await client.from('task_comments').insert({
      'task_id': taskId,
      'user_id': currentUserId,
      'content': content,
    }).select('*, profiles(*)').single();
    return TaskComment.fromJson(response);
  }

  Future<void> deleteComment(String commentId) async {
    await client.from('task_comments').delete().eq('id', commentId);
  }

  // rela time sync

  RealtimeChannel subscribeToTasks(String projectId,
      void Function(Map<String, dynamic>) onEvent,) {
    return client
        .channel('tasks:$projectId')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tasks',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'project_id',
        value: projectId,
      ),
      callback: (payload) => onEvent(payload.newRecord),
    )
        .subscribe();
  }

  // dashboard

  Future<Map<String, dynamic>> getDashboardStats() async {
    final memberProjects = await client
        .from('project_members')
        .select('project_id')
        .eq('user_id', currentUserId!);

    final projectIds = memberProjects.map((e) => e['project_id'] as String)
        .toList();

    final myTasks = await client
        .from('tasks')
        .select('status, due_date')
        .eq('assignee_id', currentUserId!);

    print("USER ID: $currentUserId");
    print("PROJECT IDS: $projectIds");
    print("MY TASKS COUNT: ${myTasks.length}");

    final overdue = myTasks.where((t) {
      final due = t['due_date'];
      return due != null &&
          DateTime.parse(due).isBefore(DateTime.now()) &&
          t['status'] != 'done';
    }).length;

    return {
      'total_projects': projectIds.length, // still valid
      'my_tasks': myTasks.length,
      'completed_tasks': myTasks
          .where((t) => t['status'] == 'done')
          .length,
      'overdue_tasks': overdue,
    };
  }
}
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'] ?? json['email'].split('@')[0],
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'avatar_url': avatarUrl,
  };

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

class Project {
  final String id;
  final String name;
  final String? description;
  final String color;
  final String status;
  final String ownerId;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;


  final int? memberCount;
  final int? totalTasks;
  final int? completedTasks;
  final int? overdueTasks;
  final String? userRole;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.color,
    required this.status,
    required this.ownerId,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount,
    this.totalTasks,
    this.completedTasks,
    this.overdueTasks,
    this.userRole,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: json['color'] ?? '#6366f1',
      status: json['status'] ?? 'active',
      ownerId: json['owner_id'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      memberCount: json['member_count'],
      totalTasks: json['total_tasks'],
      completedTasks: json['completed_tasks'],
      overdueTasks: json['overdue_tasks'],
      userRole: json['user_role'],
    );
  }

  double get progress {
    if (totalTasks == null || totalTasks == 0) return 0;
    return (completedTasks ?? 0) / totalTasks!;
  }

  bool get isAdmin => userRole == 'admin';
}

class ProjectMember {
  final String id;
  final String projectId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final UserProfile? profile;

  ProjectMember({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.profile,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: json['id'],
      projectId: json['project_id'],
      userId: json['user_id'],
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
      profile: json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null,
    );
  }

  bool get isAdmin => role == 'admin';
}

class Task {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? assigneeId;
  final String? createdBy;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? assignee;
  final UserProfile? creator;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.createdBy,
    this.dueDate,
    this.completedAt,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.assignee,
    this.creator,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      projectId: json['project_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'medium',
      assigneeId: json['assignee_id'] as String?,
      createdBy: json['created_by'] as String?,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: DateTime.parse(json['updated_at']),
      assignee: json['assignee'] != null ? UserProfile.fromJson(json['assignee']) : null,
      creator: json['creator'] != null ? UserProfile.fromJson(json['creator']) : null,
    );
  }

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && status != 'done';
  bool get isDone => status == 'done';

  Task copyWith({
    String? status,
    String? priority,
    String? assigneeId,
    String? title,
    String? description,
    DateTime? dueDate,
  }) {
    return Task(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assigneeId: assigneeId ?? this.assigneeId,
      createdBy: createdBy,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt,
      tags: tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      assignee: assignee,
      creator: creator,
    );
  }
}

class TaskComment {
  final String id;
  final String taskId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final UserProfile? user;

  TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.user,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'],
      taskId: json['task_id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['profiles'] != null ? UserProfile.fromJson(json['profiles']) : null,
    );
  }
}


class TaskStatus {
  static const todo = 'todo';
  static const inProgress = 'in_progress';
  static const review = 'review';
  static const done = 'done';

  static const all = [todo, inProgress, review, done];

  static String label(String status) {
    switch (status) {
      case todo: return 'To Do';
      case inProgress: return 'In Progress';
      case review: return 'Review';
      case done: return 'Done';
      default: return status;
    }
  }
}

class TaskPriority {
  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';
  static const urgent = 'urgent';
  static const all = [low, medium, high, urgent];
}

class ProjectRole {
  static const admin = 'admin';
  static const member = 'member';
}
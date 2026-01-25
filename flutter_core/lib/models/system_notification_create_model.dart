class SystemNotificationCreate {
  final String title;
  final String content;
  final int priority;
  final List<int>? targetUsers;
  final Map<String, dynamic>? pattern;

  SystemNotificationCreate({
    required this.title,
    required this.content,
    this.priority = 5,
    this.targetUsers,
    this.pattern,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'priority': priority,
      'target_users': targetUsers,
      'pattern': pattern,
    };
  }
}

class CRMTask {
  final String id;
  final String title;
  final String? description;
  final String status; // TaskStatus enum
  final DateTime? dueDate;
  final String organizationId;
  final String? assignedUserId;
  final String? createdById;
  final String priority; // TaskPriority enum
  final String? calendarEventId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CRMTask({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.dueDate,
    required this.organizationId,
    this.assignedUserId,
    this.createdById,
    required this.priority,
    this.calendarEventId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CRMTask.fromJson(Map<String, dynamic> json) {
    return CRMTask(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      organizationId: json['organizationId'],
      assignedUserId: json['assignedUserId'],
      createdById: json['createdById'],
      priority: json['priority'],
      calendarEventId: json['calendarEventId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'dueDate': dueDate?.toIso8601String(),
      'organizationId': organizationId,
      'assignedUserId': assignedUserId,
      'priority': priority,
    };
  }
}

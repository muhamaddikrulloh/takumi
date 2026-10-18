import 'package:cloud_firestore/cloud_firestore.dart';

import 'task_status.dart';

class Task {
  final String id;
  final String title;
  final String subject;
  final String description;
  final DateTime deadline;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    String? title,
    String? subject,
    String? description,
    DateTime? deadline,
    TaskStatus? status,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'subject': subject,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'status': status.name,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory Task.fromFirestoreMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      subject: map['subject'] as String,
      description: map['description'] as String? ?? '',
      deadline: (map['deadline'] as Timestamp).toDate(),
      status: TaskStatus.fromString(map['status'] as String),
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
    );
  }
}

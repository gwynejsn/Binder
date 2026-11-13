import 'package:binder/models/enums/priority.dart';
import 'package:binder/models/todo_attachment.dart';

class TodoItem {
  final String id;
  final String title;
  final String notes;
  final Priority priority;
  final DateTime? deadline; // nullable: user picks or no due date set
  // ito yung photos attached to each todo
  final List<TodoAttachment> attachments;
  final String? binderId;
  final bool isCompleted;
  final int completedPomodoros;
  final DateTime createdAt;

  TodoItem({
    required this.id,
    required this.title,
    this.notes = '',
    this.priority = Priority.medium, //default to med
    this.deadline,
    this.attachments = const [],
    this.binderId,
    this.isCompleted = false,
    this.completedPomodoros = 0,
    required this.createdAt,
  });

  // a utility function for easy copying
  TodoItem copyWith({
    String? title,
    String? notes,
    Priority? priority,
    DateTime? deadline,
    bool clearDeadline = false,
    List<TodoAttachment>? attachments,
    String? binderId,
    bool clearBinder = false,
    bool? isCompleted,
    int? completedPomodoros,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      attachments: attachments ?? this.attachments,
      binderId: clearBinder ? null : (binderId ?? this.binderId),
      isCompleted: isCompleted ?? this.isCompleted,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
      createdAt: createdAt,
    );
  }
}

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
}

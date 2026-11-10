import 'package:binder/models/enums/priority.dart';
import 'package:binder/models/enums/todo_filter.dart';
import 'package:binder/models/todo_attachment.dart';
import 'package:binder/models/todo_item.dart';
import 'package:binder/repositories/todo_repository.dart';

class TodosController {
  final TodoRepository _repo = TodoRepository();

  List<TodoItem> _todos = [];
  List<TodoItem> get allTodos => _todos;

  // load todos from the SQLite database
  Future<List<TodoItem>> loadTodos() async {
    _todos = await _repo.getTodos();
    return _todos;
  }

  // filter todos based on active tab
  List<TodoItem> getFilteredTodos(TodoFilter filter) {
    if (filter == TodoFilter.completed) {
      return _todos.where((t) => t.isCompleted).toList();
    }

    if (filter == TodoFilter.today) {
      final now = DateTime.now();
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final todayStart = DateTime(now.year, now.month, now.day);

      return _todos.where((t) {
        if (t.isCompleted) return false;

        // if deadline is set, check if it's due today or overdue
        if (t.deadline != null) {
          return t.deadline!.isBefore(todayEnd);
        }

        // if no deadline, check if it was created today
        final createdDate = DateTime(
          t.createdAt.year,
          t.createdAt.month,
          t.createdAt.day,
        );
        return createdDate.isAtSameMomentAs(todayStart);
      }).toList();
    }
    // default to active
    return _todos.where((t) => !t.isCompleted).toList();
  }

  // Add a new todo item
  Future<TodoItem> addTodo({
    required String title,
    String notes = '',
    Priority priority = Priority.medium,
    DateTime? deadline,
    String? binderId,
    List<TodoAttachment> attachments = const [],
  }) async {
    final newTodo = TodoItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      notes: notes,
      priority: priority,
      deadline: deadline,
      binderId: binderId,
      attachments: attachments,
      isCompleted: false,
      completedPomodoros: 0,
      createdAt: DateTime.now(),
    );

    // save to SQLite
    await _repo.insertTodo(newTodo);
    // also update our list
    _todos.insert(0, newTodo);

    return newTodo;
  }

  // Toggle task completed state
  Future<void> toggleComplete(String id, bool isCompleted) async {
    await _repo.toggleComplete(id, isCompleted);

    // update what is in our list
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final existing = _todos[index];
      _todos[index] = TodoItem(
        id: existing.id,
        title: existing.title,
        notes: existing.notes,
        priority: existing.priority,
        deadline: existing.deadline,
        binderId: existing.binderId,
        isCompleted: isCompleted,
        completedPomodoros: existing.completedPomodoros,
        createdAt: existing.createdAt,
        attachments: existing.attachments,
      );
    }
  }

  // Update an existing todo
  Future<void> updateTodo(TodoItem updated) async {
    await _repo.updateTodo(updated);

    // update what is in our list
    final index = _todos.indexWhere((t) => t.id == updated.id);
    if (index != -1) {
      _todos[index] = updated;
    }
  }

  // Delete a todo
  Future<void> deleteTodo(String id) async {
    await _repo.deleteTodo(id);
    // update what is in our list
    _todos.removeWhere((t) => t.id == id);
  }
}

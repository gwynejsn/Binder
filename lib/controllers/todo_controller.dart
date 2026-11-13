import 'package:binder/models/enums/priority.dart';
import 'package:binder/models/enums/todo_filter.dart';
import 'package:binder/models/todo_attachment.dart';
import 'package:binder/models/todo_item.dart';
import 'package:binder/repositories/todo_repository.dart';
import 'package:binder/services/photo_service.dart';

class TodoController {
  final TodoRepository _repo = TodoRepository();

  // static so that we only have 1 copy of the todos in our in-memory
  static List<TodoItem> _todos = [];
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

  //toggle task completed state
  Future<void> toggleComplete(
    TodoItem todo,
    bool isCompleted, {
    bool deletePhotos = false,
  }) async {
    List<TodoAttachment> updatedAttachments = todo.attachments;

    if (deletePhotos) {
      final photoService = PhotoService();

      for (final att in todo.attachments) {
        //check if any OTHER task in our list is using this same photo!
        final isUsedInOtherTodo = _todos.any(
          (t) =>
              t.id != todo.id &&
              t.attachments.any((a) => a.assetId == att.assetId),
        );

        // and only delete from the iPhone Camera Roll if NO other task is using it!
        if (!isUsedInOtherTodo) {
          await photoService.deleteAssetFromDevice(att.assetId);
        }
      }

      // remove the attachments from this completed task
      updatedAttachments = const [];
    }

    final updatedTodo = todo.copyWith(
      isCompleted: isCompleted,
      attachments: updatedAttachments,
    );
    await _repo.updateTodo(updatedTodo);

    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = updatedTodo;
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

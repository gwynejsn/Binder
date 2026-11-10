import 'package:binder/models/enums/priority.dart';
import 'package:binder/models/todo_attachment.dart';
import 'package:binder/models/todo_item.dart';
import 'package:binder/services/database_service.dart';

class TodoRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<List<TodoItem>> getTodos() async {
    final db = await _dbService.getDatabase();

    // query todos ordered by creation date (newest first)
    final List<Map<String, dynamic>> todoRows = await db.query(
      'todos',
      orderBy: 'created_at DESC',
    );

    final List<TodoItem> todos = [];

    for (final row in todoRows) {
      final todoId = row['id'] as String;

      // query attachments belonging to this specific todo
      final List<Map<String, dynamic>> attachmentRows = await db.query(
        'todo_attachments',
        where: 'todo_id = ?',
        whereArgs: [todoId],
      );

      final attachments = attachmentRows.map((attRow) {
        return TodoAttachment(
          path: attRow['path'] as String?,
          assetId: attRow['asset_id'] as String?,
          thumbUri: attRow['thumb_uri'] as String?,
        );
      }).toList();

      // convert Priority string back to enum
      final priority = Priority.values.firstWhere(
        (p) => p.name == row['priority'],
        orElse: () => Priority.medium,
      );

      todos.add(
        TodoItem(
          id: todoId,
          title: row['title'] as String,
          notes: row['notes'] as String? ?? '',
          priority: priority,
          deadline: row['deadline'] != null
              ? DateTime.tryParse(row['deadline'] as String)
              : null,
          binderId: row['binder_id'] as String?,
          isCompleted: (row['is_completed'] as int) == 1,
          completedPomodoros: row['completed_pomodoros'] as int? ?? 0,
          createdAt: DateTime.parse(row['created_at'] as String),
          attachments: attachments,
        ),
      );
    }

    return todos;
  }

  // insert a new todo along with any attachments
  Future<void> insertTodo(TodoItem todo) async {
    final db = await _dbService.getDatabase();

    // insert todo record
    await db.insert('todos', {
      'id': todo.id,
      'title': todo.title,
      'notes': todo.notes,
      'priority': todo.priority.name,
      'deadline': todo.deadline?.toIso8601String(),
      'binder_id': todo.binderId,
      'is_completed': todo.isCompleted ? 1 : 0,
      'completed_pomodoros': todo.completedPomodoros,
      'created_at': todo.createdAt.toIso8601String(),
    });

    // insert each attachment
    for (final att in todo.attachments) {
      if (att.isValid) {
        await db.insert('todo_attachments', {
          'todo_id': todo.id,
          'path': att.path,
          'asset_id': att.assetId,
          'thumb_uri': att.thumbUri,
        });
      }
    }
  }

  // toggle completion status
  Future<void> toggleComplete(String id, bool isCompleted) async {
    final db = await _dbService.getDatabase();
    await db.update(
      'todos',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // update an existing todo and its attachments
  Future<void> updateTodo(TodoItem todo) async {
    final db = await _dbService.getDatabase();

    // update main todo row
    await db.update(
      'todos',
      {
        'title': todo.title,
        'notes': todo.notes,
        'priority': todo.priority.name,
        'deadline': todo.deadline?.toIso8601String(),
        'binder_id': todo.binderId,
        'is_completed': todo.isCompleted ? 1 : 0,
        'completed_pomodoros': todo.completedPomodoros,
      },
      where: 'id = ?',
      whereArgs: [todo.id],
    );

    // refresh attachments: delete old ones and insert updated ones
    await db.delete(
      'todo_attachments',
      where: 'todo_id = ?',
      whereArgs: [todo.id],
    );

    for (final att in todo.attachments) {
      if (att.isValid) {
        await db.insert('todo_attachments', {
          'todo_id': todo.id,
          'path': att.path,
          'asset_id': att.assetId,
          'thumb_uri': att.thumbUri,
        });
      }
    }
  }

  // delete a todo (SQLite cascade deletes the attachments automatically)
  Future<void> deleteTodo(String id) async {
    final db = await _dbService.getDatabase();
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }
}

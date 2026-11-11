import 'dart:io';

import 'package:binder/controllers/todo_controller.dart';
import 'package:binder/models/enums/priority.dart';
import 'package:binder/models/enums/todo_filter.dart';
import 'package:binder/models/todo_item.dart';
import 'package:binder/screens/create_todo_screen.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TodoController _controller = TodoController();
  TodoFilter _filter = TodoFilter.active;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.loadTodos();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleComplete(TodoItem todo, bool isCompleted) async {
    await _controller.toggleComplete(todo.id, isCompleted);
    setState(() {});
  }

  Future<void> _deleteTodo(String id) async {
    await _controller.deleteTodo(id);
    setState(() {});
  }

  void _openCreateTaskScreen() async {
    // returns true if saved or false if not
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTodoScreen(controller: _controller),
      ),
    );

    // after the task was saved, refresh the list
    if (created == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.terracotta),
        ),
      );
    }

    final activeTodos = _controller.getFilteredTodos(TodoFilter.active);
    final todayTodos = _controller.getFilteredTodos(TodoFilter.today);
    final completedTodos = _controller.getFilteredTodos(TodoFilter.completed);
    final displayedTodos = _controller.getFilteredTodos(_filter);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDateToday(DateTime.now()).toUpperCase(),
              style: AppTheme.overline(
                fontSize: 10,
                color: AppTheme.terracottaLight,
              ),
            ),
            const SizedBox(height: 2),
            Text('Agenda', style: AppTheme.serifHeading(fontSize: 22)),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: FloatingActionButton(
          onPressed: _openCreateTaskScreen,
          backgroundColor: AppTheme.terracotta,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
      body: Column(
        children: [
          // filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(
                  TodoFilter.active,
                  'Active (${activeTodos.length})',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  TodoFilter.today,
                  'Today (${todayTodos.length})',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  TodoFilter.completed,
                  'Done (${completedTodos.length})',
                ),
              ],
            ),
          ),

          // task List
          Expanded(
            child: displayedTodos.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    // list view para scrollable!
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 120,
                    ),
                    itemCount: displayedTodos.length,
                    itemBuilder: (context, index) {
                      final todo = displayedTodos[index];
                      return _buildTodoCard(todo);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TodoFilter filter, String label) {
    final isSelected = _filter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceElevated : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.terracotta : AppTheme.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTheme.sans(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodoCard(TodoItem todo) {
    // https: //api.flutter.dev/flutter/widgets/Dismissible-class.html
    return Dismissible(
      key: ValueKey('todo_${todo.id}'),
      direction:
          DismissDirection.endToStart, // right to left slide to delete the todo
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.rose.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _deleteTodo(todo.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // circle checkbox
            GestureDetector(
              onTap: () => _toggleComplete(todo, !todo.isCompleted),
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: todo.isCompleted ? AppTheme.sage : Colors.transparent,
                  border: Border.all(
                    color: todo.isCompleted
                        ? AppTheme.sage
                        : AppTheme.textTertiary,
                    width: 2,
                  ),
                ),
                child: todo.isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: _priorityColor(todo.priority)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _priorityColor(todo.priority)
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          todo.priority.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: _priorityColor(todo.priority),
                          ),
                        ),
                      ),

                      // deadline
                      if (todo.deadline != null)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(todo.deadline!),
                              style: AppTheme.sans(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // title
                  Text(
                    todo.title,
                    style:
                        AppTheme.sans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: todo.isCompleted
                              ? AppTheme.textTertiary
                              : AppTheme.textPrimary,
                        ).copyWith(
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                  if (todo.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      todo.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.sans(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildAttachedPhotos(todo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 52,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            _filter == TodoFilter.active
                ? 'No active tasks!'
                : _filter == TodoFilter.today
                ? 'Nothing due or scheduled for today'
                : 'No completed tasks yet',
            style: AppTheme.sans(
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedPhotos(TodoItem todo) {
    if (todo.attachments.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 72,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: todo.attachments.length,
        itemBuilder: (context, index) {
          final photo = todo.attachments[index];
          if (photo.path == null)
            return const SizedBox.shrink(); // .shrink with height and size of 0

          return GestureDetector(
            onTap: () => _openImageViewer(photo.path!),
            child: Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
              ),
              child: Image.file(File(photo.path!), fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  void _openImageViewer(String imagePath) {
    // https://api.flutter.dev/flutter/material/showDialog.html
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      // https://api.flutter.dev/flutter/material/Dialog-class.html
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.file(File(imagePath), fit: BoxFit.contain),

            // close button
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(Priority p) {
    switch (p) {
      case Priority.high:
        return AppTheme.rose;
      case Priority.medium:
        return AppTheme.wheat;
      case Priority.low:
        return AppTheme.sage;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  String _formatDateToday(DateTime dt) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[dt.weekday - 1]} • ${months[dt.month - 1]} ${dt.day}';
  }
}

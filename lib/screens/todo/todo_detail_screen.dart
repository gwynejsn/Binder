import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/controllers/todo_controller.dart';
import 'package:binder/models/enums/priority.dart';
import 'package:binder/models/todo_attachment.dart';
import 'package:binder/models/todo_item.dart';
import 'package:binder/services/photo_service.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/color_utils.dart';
import 'package:binder/utils/format_utils.dart';
import 'package:binder/utils/photo_utils.dart';
import 'package:binder/widgets/BinderSelector.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class TodoDetailScreen extends StatefulWidget {
  final TodoItem todo;

  const TodoDetailScreen({super.key, required this.todo});

  @override
  State<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends State<TodoDetailScreen> {
  final TodoController _todoController = TodoController();
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  final BinderController _binderController = BinderController();

  late Priority _selectedPriority;
  late DateTime? _selectedDeadline;
  late bool _isCompleted;
  late List<TodoAttachment> _attachments;
  bool _isSaving = false;
  String? _selectedBinderId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.todo.title);
    _notesController = TextEditingController(text: widget.todo.notes);
    _selectedPriority = widget.todo.priority;
    _selectedDeadline = widget.todo.deadline;
    _isCompleted = widget.todo.isCompleted;
    _attachments = List<TodoAttachment>.from(widget.todo.attachments);
    _selectedBinderId = widget.todo.binderId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _pickPhotos() async {
    final assets = await PhotoService().pickPhotos(context, maxAssets: 5);
    if (assets.isNotEmpty) {
      setState(() {
        _attachments.addAll(
          assets.map((asset) => TodoAttachment(assetId: asset.id)),
        );
      });
    }
  }

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    final updated = TodoItem(
      id: widget.todo.id,
      title: title,
      notes: _notesController.text.trim(),
      priority: _selectedPriority,
      deadline: _selectedDeadline,
      binderId: _selectedBinderId,
      isCompleted: _isCompleted,
      completedPomodoros: widget.todo.completedPomodoros,
      createdAt: widget.todo.createdAt,
      attachments: _attachments,
    );

    await _todoController.updateTodo(updated);

    if (mounted) {
      Navigator.pop(context, true); // true = changes saved
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text(
          'Delete Task?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Are you sure you want to permanently delete this task?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _todoController.deleteTodo(widget.todo.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textSecondary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Task Details', style: AppTheme.serifHeading(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.rose,
            ),
            onPressed: _deleteTask,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.terracotta,
                      ),
                    )
                  : Text(
                      'Save',
                      style: AppTheme.sans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.terracotta,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // completion status toggle row
            GestureDetector(
              onTap: () => setState(() => _isCompleted = !_isCompleted),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCompleted
                            ? AppTheme.sage
                            : Colors.transparent,
                        border: Border.all(
                          color: _isCompleted
                              ? AppTheme.sage
                              : AppTheme.textTertiary,
                          width: 2,
                        ),
                      ),
                      child: _isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.black,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isCompleted
                          ? 'Marked as Completed'
                          : 'Mark as Completed',
                      style: AppTheme.sans(
                        fontSize: 14,
                        color: _isCompleted
                            ? AppTheme.sage
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // title field
            TextField(
              controller: _titleController,
              style: AppTheme.sans(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Task title...',
                hintStyle: AppTheme.sans(
                  fontSize: 18,
                  color: AppTheme.textTertiary,
                ),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: AppTheme.border, height: 24),

            // notes field
            TextField(
              controller: _notesController,
              maxLines: 5,
              minLines: 2,
              style: AppTheme.sans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Notes or details...',
                hintStyle: AppTheme.sans(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                ),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: AppTheme.border, height: 24),

            // priority selector
            Text('PRIORITY', style: AppTheme.overline(fontSize: 11)),
            const SizedBox(height: 10),
            Row(
              children: Priority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ChoiceChip(
                    label: Text(
                      priority.name.toUpperCase(),
                      style: AppTheme.overline(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.black
                            : AppTheme.textSecondary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: ColorUtils.priorityColor(priority),
                    backgroundColor: AppTheme.surface,
                    onSelected: (val) {
                      if (val) setState(() => _selectedPriority = priority);
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // binder
            BinderSelector(
              selectedBinderId: _selectedBinderId,
              onSelected: (id) => setState(() => _selectedBinderId = id),
            ),
            const SizedBox(height: 24),

            //Due Date section
            Text('DUE DATE', style: AppTheme.overline(fontSize: 11)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDeadline,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppTheme.terracotta,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDeadline == null
                            ? 'No deadline set'
                            : FormatUtils.formatDateWithYear(
                                _selectedDeadline!,
                              ),
                        style: AppTheme.sans(
                          color: _selectedDeadline == null
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (_selectedDeadline != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedDeadline = null),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // attachments section
            Text(
              'ATTACHMENTS (${_attachments.length})',
              style: AppTheme.overline(fontSize: 11),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // add photo button
                  GestureDetector(
                    onTap: _pickPhotos,
                    child: Container(
                      width: 76,
                      height: 76,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Icon(
                        Icons.add_a_photo_outlined,
                        color: AppTheme.terracotta,
                        size: 24,
                      ),
                    ),
                  ),

                  //display attached photos
                  for (int i = 0; i < _attachments.length; i++)
                    _buildAttachmentItem(i),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(int index) {
    final att = _attachments[index];

    return Container(
      width: 76,
      height: 76,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<AssetEntity?>(
            future: AssetEntity.fromId(att.assetId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return GestureDetector(
                  onTap: () => PhotoUtils.openImageViewer(context, att),
                  child: AssetEntityImage(
                    snapshot.data!,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(200),
                    fit: BoxFit.cover,
                  ),
                );
              }
              return Container(color: AppTheme.surface);
            },
          ),

          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => setState(() => _attachments.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

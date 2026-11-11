import 'package:binder/controllers/todo_controller.dart';
import 'package:binder/models/enums/priority.dart';
import 'package:binder/models/todo_attachment.dart';
import 'package:binder/services/photo_service.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/color_utils.dart';
import 'package:binder/utils/format_utils.dart';
import 'package:binder/utils/photo_utils.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CreateTodoScreen extends StatefulWidget {
  final TodoController controller;

  const CreateTodoScreen({super.key, required this.controller});

  @override
  State<CreateTodoScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTodoScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  Priority _selectedPriority = Priority.medium;
  DateTime? _selectedDeadline;
  final List<TodoAttachment> _attachments = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    await widget.controller.addTodo(
      title: title,
      notes: _notesController.text.trim(),
      priority: _selectedPriority,
      deadline: _selectedDeadline,
      attachments: _attachments,
    );

    if (mounted) {
      // return 'true' to signal that a task was created
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    // https://api.flutter.dev/flutter/material/showDatePicker.html
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  // we used this to pick photos
  // https://pub.dev/packages/image_picker
  Future<void> _pickPhotos() async {
    final newPhotos = await PhotoService().pickPhotos(context);
    if (newPhotos.isNotEmpty) {
      setState(() {
        _attachments.addAll(newPhotos);
      });
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
          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('New Task', style: AppTheme.serifHeading(fontSize: 20)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton(
              onPressed: _isSaving ? null : _saveTask,
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
      // https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // task title
            TextField(
              controller: _titleController,
              autofocus: true,
              style: AppTheme.sans(fontSize: 18, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                hintStyle: AppTheme.sans(
                  fontSize: 18,
                  color: AppTheme.textTertiary,
                ),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: AppTheme.border, height: 24),

            // notes
            TextField(
              controller: _notesController,
              maxLines: 4,
              minLines: 2,
              style: AppTheme.sans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add notes or details...',
                hintStyle: AppTheme.sans(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                ),
                border: InputBorder.none,
              ),
            ),
            const Divider(color: AppTheme.border, height: 24),

            // priority
            Text('PRIORITY', style: AppTheme.overline(fontSize: 11)),
            const SizedBox(height: 10),
            Row(
              children: Priority.values.map((priority) {
                final isSelected = _selectedPriority == priority;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  // https://api.flutter.dev/flutter/material/ChoiceChip-class.html
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
                      if (val) {
                        setState(() => _selectedPriority = priority);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // deadline
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
                    // clear the current selected deadline
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

            // attachments
            Text('ATTACHMENTS', style: AppTheme.overline(fontSize: 11)),
            const SizedBox(height: 10),

            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // add photo button
                  GestureDetector(
                    onTap: _pickPhotos,
                    child: Container(
                      width: 72,
                      height: 72,
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

                  // display photo preview for each image selected
                  for (int i = 0; i < _attachments.length; i++)
                    buildPhotoItem(i),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPhotoItem(int index) {
    final attachment = _attachments[index];

    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<AssetEntity?>(
            future: AssetEntity.fromId(attachment.assetId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return GestureDetector(
                  onTap: () => PhotoUtils.openImageViewer(context, attachment),
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

          // delete (X) button
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _attachments.removeAt(index);
                });
              },
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

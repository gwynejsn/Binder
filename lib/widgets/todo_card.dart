import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/models/enums/priority.dart';
import 'package:binder/models/todo_item.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/color_utils.dart';
import 'package:binder/utils/format_utils.dart';
import 'package:binder/utils/photo_utils.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final ValueChanged<bool> onToggleComplete;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool showBinderTag;

  const TodoCard({
    super.key,
    required this.todo,
    required this.onToggleComplete,
    required this.onTap,
    this.onDelete,
    this.showBinderTag = true,
  });

  Color _priorityColor(Priority priority) {
    return ColorUtils.priorityColor(priority);
  }

  Widget _buildBinderTag(String? binderId) {
    if (binderId == null || !showBinderTag) return const SizedBox.shrink();

    final binder = BinderController().getBinderById(binderId);
    if (binder == null) return const SizedBox.shrink();

    final color = ColorUtils.getColor(binder.colorHex);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_rounded, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            binder.name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachedPhotos(BuildContext context) {
    if (todo.attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 72,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: todo.attachments.length,
        itemBuilder: (ctx, index) {
          final photo = todo.attachments[index];

          return GestureDetector(
            onTap: () => PhotoUtils.openImageViewer(context, photo),
            child: Container(
              width: 72,
              height: 72,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: FutureBuilder<AssetEntity?>(
                future: AssetEntity.fromId(photo.assetId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return AssetEntityImage(
                      snapshot.data!,
                      isOriginal: false,
                      thumbnailSize: const ThumbnailSize.square(200),
                      fit: BoxFit.cover,
                    );
                  }
                  return Container(color: AppTheme.surface);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = GestureDetector(
      onTap: onTap,
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
            GestureDetector(
              onTap: () => onToggleComplete(!todo.isCompleted),
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
                      //priority
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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

                      _buildBinderTag(todo.binderId),

                      // deadline
                      if (todo.deadline != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              FormatUtils.formatDateWithYear(todo.deadline!),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  //title
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

                  //notes (no spread ...)
                  if (todo.notes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        todo.notes,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis, // use ellipses when overflow
                        style: AppTheme.sans(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),

                  _buildAttachedPhotos(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    //if onDelete is provided, wrap in swipe-to-delete Dismissible
    if (onDelete != null) {
      return Dismissible(
        key: ValueKey('todo_${todo.id}'),
        direction: DismissDirection.endToStart,
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
        onDismissed: (_) => onDelete!(),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

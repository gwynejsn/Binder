import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/color_utils.dart';
import 'package:flutter/material.dart';

// sa may todo, when selecting which binder to assign it, ito yung widget
class BinderSelector extends StatelessWidget {
  final String? selectedBinderId;
  final ValueChanged<String?> onSelected;

  const BinderSelector({
    super.key,
    required this.selectedBinderId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final binders = BinderController().allBinders;
    final List<Widget> chips = [];

    // no folder chip
    final isNoneSelected = selectedBinderId == null;
    chips.add(
      GestureDetector(
        onTap: () => onSelected(null),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isNoneSelected ? AppTheme.surfaceElevated : AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isNoneSelected ? AppTheme.terracotta : AppTheme.border,
            ),
          ),
          child: Text(
            'No Folder',
            style: AppTheme.sans(
              fontSize: 12,
              color: isNoneSelected
                  ? AppTheme.textPrimary
                  : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );

    for (final binder in binders) {
      // assign the selected binder to save the binderId in the todo model
      final isSelected = selectedBinderId == binder.id;
      final color = ColorUtils.getColor(binder.colorHex);

      chips.add(
        GestureDetector(
          onTap: () => onSelected(binder.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.18)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? color : AppTheme.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_rounded, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  binder.name,
                  style: AppTheme.sans(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BINDER', style: AppTheme.overline(fontSize: 11)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }
}

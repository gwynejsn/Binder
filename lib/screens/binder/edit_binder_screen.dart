import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/models/binder.dart';
import 'package:binder/screens/binder/binder_keywords_screen.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/color_utils.dart';
import 'package:flutter/material.dart';

class EditBinderScreen extends StatefulWidget {
  final Binder binder;

  const EditBinderScreen({super.key, required this.binder});

  @override
  State<EditBinderScreen> createState() => _EditBinderScreenState();
}

class _EditBinderScreenState extends State<EditBinderScreen> {
  final BinderController _binderController = BinderController();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedColorHex;
  late String _currentKeywords;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.binder.name);
    _descController = TextEditingController(text: widget.binder.description);
    _selectedColorHex = widget.binder.colorHex;
    _currentKeywords = widget.binder.keywords;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // if we ever update the keywords from another screen
    // we need to refetch the binder
    // also we track the current keywords since earlier there was
    // a bug that deletes the already saved keywords when saving again
    // as the binder here is not updated!
    final latest =
        _binderController.getBinderById(widget.binder.id) ?? widget.binder;
    final updated = latest.copyWith(
      name: name,
      description: _descController.text.trim(),
      colorHex: _selectedColorHex,
      keywords: _currentKeywords,
    );

    await _binderController.updateBinder(updated);
    if (mounted) Navigator.pop(context, 'saved');
  }

  Future<void> _deleteBinder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Binder?'),
        content: Text(
          'Delete "${widget.binder.name}"? Tasks inside will stay in your Todo list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _binderController.deleteBinder(widget.binder.id);
      if (mounted) Navigator.pop(context, 'deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keywordCount = _currentKeywords
        .split(' ')
        .where((k) => k.trim().isNotEmpty)
        .length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        title: Text('Edit Binder', style: AppTheme.serifHeading(fontSize: 20)),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.terracotta,
                fontWeight: FontWeight.w600,
                fontSize: 16,
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
            Text('BINDER NAME', style: AppTheme.overline(fontSize: 11)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: AppTheme.sans(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. School, Work, Finance',
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'DESCRIPTION (OPTIONAL)',
              style: AppTheme.overline(fontSize: 11),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 2,
              style: AppTheme.sans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'What goes in this binder...',
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text('BINDER COLOR', style: AppTheme.overline(fontSize: 11)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: AppTheme.binderColors.map((hex) {
                final color = ColorUtils.getColor(hex);
                final isSelected = _selectedColorHex == hex;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColorHex = hex),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            Center(
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BinderKeywordsScreen(binderId: widget.binder.id),
                    ),
                  );

                  // Update keywords in local state when returning from keywords screen
                  if (result == true) {
                    final latest = _binderController.getBinderById(
                      widget.binder.id,
                    );
                    if (latest != null && mounted) {
                      setState(() {
                        // we track the keywords so it is consistent
                        _currentKeywords = latest.keywords;
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.terracotta.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppTheme.terracotta,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        keywordCount > 0
                            ? 'Edit Keywords ($keywordCount)'
                            : 'Edit Keywords',
                        style: const TextStyle(
                          color: AppTheme.terracotta,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 36),

            Center(
              child: GestureDetector(
                onTap: _deleteBinder,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.rose.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppTheme.rose,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Delete Binder',
                        style: TextStyle(
                          color: AppTheme.rose,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

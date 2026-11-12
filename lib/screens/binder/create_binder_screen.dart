import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/color_utils.dart';
import 'package:flutter/material.dart';

class CreateBinderScreen extends StatefulWidget {
  const CreateBinderScreen({super.key});

  @override
  State<CreateBinderScreen> createState() => _CreateBinderScreenState();
}

class _CreateBinderScreenState extends State<CreateBinderScreen> {
  final BinderController _binderController = BinderController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();

  String _selectedColorHex = AppTheme.binderColors[0]; //default to blue

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  Future<void> _createBinder() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await _binderController.addBinder(
      name: name,
      description: _descController.text.trim(),
      colorHex: _selectedColorHex,
      keywords: _keywordsController.text.trim(),
    );

    if (mounted) {
      Navigator.pop(context, true); //returns true to trigger reload
    }
  }

  List<Widget> _buildColorOptions() {
    final List<Widget> colorWidgets = [];

    for (final hex in AppTheme.binderColors) {
      final color = ColorUtils.getColor(hex);
      final isSelected = _selectedColorHex == hex;

      colorWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedColorHex = hex;
            });
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        ),
      );
    }

    return colorWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        title: Text('New Binder', style: AppTheme.serifHeading(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _createBinder,
            child: const Text(
              'Create',
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
              autofocus: true,
              style: AppTheme.sans(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. School, Work, Receipts',
                hintStyle: AppTheme.sans(color: AppTheme.textTertiary),
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
                hintText: 'What goes inside this folder...',
                hintStyle: AppTheme.sans(color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text('FOLDER COLOR', style: AppTheme.overline(fontSize: 11)),
            const SizedBox(height: 10),
            Wrap(spacing: 12, runSpacing: 10, children: _buildColorOptions()),
            const SizedBox(height: 28),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: AppTheme.terracotta,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Keywords (Optional)',
                        style: AppTheme.sans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Separate keywords with spaces. Put related keywords to the binder here to help AI classify it!',
                    style: AppTheme.sans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keywordsController,
                    style: AppTheme.sans(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g. math homework assignment formula',
                      hintStyle: AppTheme.sans(color: AppTheme.textTertiary),
                      filled: true,
                      fillColor: AppTheme.surfaceElevated,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

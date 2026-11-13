import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/models/binder.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BinderKeywordsScreen extends StatefulWidget {
  final String binderId;

  const BinderKeywordsScreen({super.key, required this.binderId});

  @override
  State<BinderKeywordsScreen> createState() => _BinderKeywordsScreenState();
}

class _BinderKeywordsScreenState extends State<BinderKeywordsScreen> {
  final BinderController _binderController = BinderController();
  final TextEditingController _inputController = TextEditingController();

  late Binder _binder;
  List<String> _keywords = [];
  bool _isLoading = true;

  // quick suggestions the user can tap to add
  final List<String> _suggestions = [
    'notes',
    'homework',
    'exam',
    'receipt',
    'schedule',
    'formula',
    'syllabus',
  ];

  @override
  void initState() {
    super.initState();
    _loadBinder();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _loadBinder() {
    final found = _binderController.getBinderById(widget.binderId);
    if (found != null) {
      _binder = found;
      _keywords = _binder.keywords
          .split(' ')
          .where((k) => k.trim().isNotEmpty)
          .toList();
    }
    setState(() => _isLoading = false);
  }

  void _addKeyword(String text) {
    final clean = text.trim().toLowerCase();
    if (clean.isNotEmpty && !_keywords.contains(clean)) {
      setState(() {
        _keywords.add(clean);
      });
    }
    _inputController.clear();
  }

  void _removeKeyword(int index) {
    setState(() {
      _keywords.removeAt(index);
    });
  }

  Future<void> _saveKeywords() async {
    final updated = _binder.copyWith(keywords: _keywords.join(' '));
    await _binderController.updateBinder(updated);
    if (mounted) Navigator.pop(context, true);
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        title: Text('AI Keywords', style: AppTheme.serifHeading(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: _saveKeywords,
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
            // quick description/guide
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: AppTheme.terracotta,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How this works',
                          style: AppTheme.sans(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'When you clean or scan screenshots, any OCR text matching these keywords will automatically file photos into "${_binder.name}".',
                          style: AppTheme.sans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('ADD KEYWORD', style: AppTheme.overline(fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    style: AppTheme.sans(fontSize: 14),
                    onSubmitted: _addKeyword,
                    onChanged: (val) {
                      //automatically add if user types space or comma
                      if (val.endsWith(' ') || val.endsWith(',')) {
                        _addKeyword(val.replaceAll(',', '').trim());
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Type keyword (e.g. math, receipt)...',
                      hintStyle: AppTheme.sans(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppTheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _addKeyword(_inputController.text),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CURRENT KEYWORDS',
                  style: AppTheme.overline(fontSize: 11),
                ),
                if (_keywords.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _keywords.clear()),
                    child: Text(
                      'Clear all',
                      style: AppTheme.sans(fontSize: 11, color: AppTheme.rose),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_keywords.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Center(
                  child: Text(
                    'No keywords yet.\nType above or tap suggestions below.',
                    textAlign: TextAlign.center,
                    style: AppTheme.sans(
                      fontSize: 13,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_keywords.length, (index) {
                  final keyword = _keywords[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          keyword,
                          style: AppTheme.sans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _removeKeyword(index),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            const SizedBox(height: 32),

            //suggestions
            Text('QUICK SUGGESTIONS', style: AppTheme.overline(fontSize: 11)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions.map((suggestion) {
                final alreadyAdded = _keywords.contains(suggestion);
                return GestureDetector(
                  onTap: () {
                    if (!alreadyAdded) _addKeyword(suggestion);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: alreadyAdded
                          ? AppTheme.surfaceElevated.withValues(alpha: 0.3)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: alreadyAdded
                            ? AppTheme.border
                            : AppTheme.terracotta.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          alreadyAdded ? Icons.check : Icons.add,
                          size: 13,
                          color: alreadyAdded
                              ? AppTheme.textTertiary
                              : AppTheme.terracotta,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          suggestion,
                          style: AppTheme.sans(
                            fontSize: 12,
                            color: alreadyAdded
                                ? AppTheme.textTertiary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';

// pag naubos na yung card mo, this is the widget shown in the cleaner
class CleanerEmptyState extends StatelessWidget {
  final int stagedCount;
  final VoidCallback onReviewTrash;
  final VoidCallback onRefresh;

  const CleanerEmptyState({
    super.key,
    required this.stagedCount,
    required this.onReviewTrash,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.sage.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: AppTheme.sage,
            ),
          ),
          const SizedBox(height: 16),
          Text('All Cleaned Up!', style: AppTheme.serifHeading(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            'No screenshots left to review in this album.',
            style: AppTheme.sans(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // if you have no more cards left and you have photos to review
          // redirect to the trash screen review
          if (stagedCount > 0)
            GestureDetector(
              onTap: onReviewTrash,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.rose,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Review $stagedCount Staged Photos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          GestureDetector(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(color: AppTheme.terracotta),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

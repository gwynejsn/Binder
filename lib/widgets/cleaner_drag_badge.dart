import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';

// sa may cleaner
// when you drag a bit to up down left right, a label will show
class CleanerDragBadge extends StatelessWidget {
  final int percentX;
  final int percentY;

  const CleanerDragBadge({
    super.key,
    required this.percentX,
    required this.percentY,
  });

  @override
  Widget build(BuildContext context) {
    if (percentX.abs() > percentY.abs()) {
      if (percentX > 15) {
        final double progress = (percentX / 50).clamp(0.0, 1.0);
        return Positioned(
          top: 36,
          left: 24,
          child: Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: 0.85 + (0.15 * progress),
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.sage.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'ADD TO FOLDER',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else if (percentX < -15) {
        final double progress = (percentX.abs() / 50).clamp(0.0, 1.0);
        return Positioned(
          top: 36,
          right: 24,
          child: Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: 0.85 + (0.15 * progress),
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.rose.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'DELETE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } else {
      if (percentY < -15) {
        final double progress = (percentY.abs() / 50).clamp(0.0, 1.0);
        return Positioned(
          bottom: 36,
          left: 0,
          right: 0,
          child: Center(
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: 0.85 + (0.15 * progress),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_task_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'TURN INTO TASK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (percentY > 15) {
        final double progress = (percentY / 50).clamp(0.0, 1.0);
        return Positioned(
          top: 36,
          left: 0,
          right: 0,
          child: Center(
            child: Opacity(
              opacity: progress,
              child: Transform.scale(
                scale: 0.85 + (0.15 * progress),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.wheat.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.skip_next_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'SKIP',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return const SizedBox.shrink();
  }
}

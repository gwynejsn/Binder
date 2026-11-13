import 'package:binder/models/binder.dart';
import 'package:binder/models/smart_scan_result.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/color_utils.dart';
import 'package:flutter/material.dart';

// this is the suggestion pill (yung result ng ai natin) widget
class CleanerSuggestionPill extends StatelessWidget {
  final SmartScanResult? scanResult;
  final bool isScanning;
  final List<Binder> binders;
  final VoidCallback onTap;

  const CleanerSuggestionPill({
    super.key,
    required this.scanResult,
    required this.isScanning,
    required this.binders,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String heading;
    String title;
    IconData icon;
    Color accentColor;
    String actionLabel;

    if (scanResult != null && scanResult!.suggestedBinderId != null) {
      Binder? binder;
      for (final b in binders) {
        if (b.id == scanResult!.suggestedBinderId) {
          binder = b;
          break;
        }
      }
      heading = 'SUGGESTED FOLDER';
      title = binder?.name ?? 'Suggested Folder';
      icon = Icons.folder_rounded;
      accentColor = binder != null
          ? ColorUtils.getColor(binder.colorHex)
          : AppTheme.sage;
      actionLabel = 'Change';
    } else if (scanResult != null && scanResult!.suggestedNewTopic != null) {
      final topic = scanResult!.suggestedNewTopic!;
      heading = 'NEW FOLDER SUGGESTION';
      title = '+ ${topic.name}';
      icon = Icons.create_new_folder_rounded;
      accentColor = ColorUtils.getColor(topic.colorHex);
      actionLabel = 'Create';
    } else if (isScanning) {
      heading = 'ANALYZING SCREENSHOT';
      title = 'Scanning text & folders...';
      icon = Icons.auto_awesome_rounded;
      accentColor = AppTheme.terracotta;
      actionLabel = '';
    } else {
      heading = 'MANUAL FILING';
      title = 'Choose Folder';
      icon = Icons.folder_outlined;
      accentColor = AppTheme.textSecondary;
      actionLabel = 'Select';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: isScanning
                  ? Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      ),
                    )
                  : Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    heading,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

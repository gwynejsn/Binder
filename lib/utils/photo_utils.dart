import 'package:binder/models/todo_attachment.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoUtils {
  // Accepts EITHER a String assetId OR a TodoAttachment!
  static void openImageViewer(BuildContext context, dynamic photo) {
    final String assetId = photo is TodoAttachment
        ? photo.assetId
        : photo as String;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pinch-to-zoom viewer
            InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 1.0,
              maxScale: 4.0,
              child: FutureBuilder<AssetEntity?>(
                future: AssetEntity.fromId(assetId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return AssetEntityImage(
                      snapshot.data!,
                      isOriginal: true, // Full crisp resolution
                      fit: BoxFit.contain,
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.terracotta,
                    ),
                  );
                },
              ),
            ),

            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

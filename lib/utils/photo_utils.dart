import 'package:binder/models/todo_attachment.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoUtils {
  static void openImageViewer(BuildContext context, TodoAttachment attachment) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder<AssetEntity?>(
              future: AssetEntity.fromId(attachment.assetId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return AssetEntityImage(
                    snapshot.data!,
                    isOriginal: true, // to preserve the quality
                    thumbnailSize: const ThumbnailSize.square(200),
                    fit: BoxFit.contain,
                  );
                }
                return Container(color: AppTheme.surface);
              },
            ),

            // close button
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

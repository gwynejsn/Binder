import 'dart:ui' show ImageFilter;

import 'package:binder/models/binder.dart';
import 'package:binder/models/smart_scan_result.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/photo_utils.dart';
import 'package:binder/widgets/cleaner_drag_badge.dart';
import 'package:binder/widgets/cleaner_suggestion_pill.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

//tinder card builder
class CleanerCard extends StatelessWidget {
  final AssetEntity photo;
  final int percentX;
  final int percentY;
  final bool isTop;
  final SmartScanResult? scanResult;
  final bool isScanning;
  final List<Binder> binders;
  final VoidCallback onTapSuggestion;

  const CleanerCard({
    super.key,
    required this.photo,
    required this.percentX,
    required this.percentY,
    required this.isTop,
    required this.scanResult,
    required this.isScanning,
    required this.binders,
    required this.onTapSuggestion,
  });

  // since tinder style swiper is only portrait
  // pangit tignan if landscape yung photo
  // so we do something about it:
  Widget _buildPhotoContent() {
    final bool isLandscape = photo.orientatedWidth > photo.orientatedHeight;

    if (isLandscape) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
              child: Transform.scale(
                scale: 1.25,
                child: AssetEntityImage(
                  photo,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize(300, 300),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: AssetEntityImage(
                  photo,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize(900, 600),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // show the resolution of the image when landscape
          Positioned(
            bottom: 86,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.crop_landscape_rounded,
                      color: AppTheme.wheat,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${photo.orientatedWidth} × ${photo.orientatedHeight}',
                      style: AppTheme.sans(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // default portrait!
    return AssetEntityImage(
      photo,
      isOriginal: false,
      thumbnailSize: const ThumbnailSize(800, 1200),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(
            color: AppTheme.terracotta,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppTheme.surfaceElevated,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: AppTheme.textTertiary,
            size: 48,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: _buildPhotoContent()),

          //tap to preview fullscreen
          Positioned.fill(
            child: GestureDetector(
              onTap: () => PhotoUtils.openImageViewer(context, photo.id),
              behavior: HitTestBehavior.translucent,
            ),
          ),

          if (isTop)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: CleanerSuggestionPill(
                scanResult: scanResult,
                isScanning: isScanning,
                binders: binders,
                onTap: onTapSuggestion,
              ),
            ),

          CleanerDragBadge(percentX: percentX, percentY: percentY),
        ],
      ),
    );
  }
}

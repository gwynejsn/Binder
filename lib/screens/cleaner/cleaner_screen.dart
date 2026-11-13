import 'dart:ui' show ImageFilter;

import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/screens/cleaner/review_trash_screen.dart';
import 'package:binder/screens/todo/create_todo_screen.dart';
import 'package:binder/services/photo_service.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/color_utils.dart';
import 'package:binder/utils/photo_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CleanerScreen extends StatefulWidget {
  const CleanerScreen({super.key});

  @override
  State<CleanerScreen> createState() => _CleanerScreenState();
}

class _CleanerScreenState extends State<CleanerScreen> {
  final PhotoService _photoService = PhotoService();
  final BinderController _binderController = BinderController();
  final CardSwiperController _swiperController = CardSwiperController();

  List<AssetEntity> _deck = [];
  List<AssetEntity> _stagedForDeletion = [];
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumsAndPhotos();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbumsAndPhotos() async {
    setState(() => _isLoading = true);

    final albums = await _photoService.fetchAlbums();
    if (!mounted) return;

    // prefer recent photos, or if no recent, then the first album
    AssetPathEntity? targetAlbum;
    for (final a in albums) {
      if (a.name.toLowerCase().contains('recent')) {
        targetAlbum = a;
        break;
      }
    }
    if (targetAlbum == null && albums.isNotEmpty) {
      targetAlbum = albums.first;
    }

    _albums = albums;
    _selectedAlbum = targetAlbum;

    if (targetAlbum != null) {
      final photos = await _photoService.fetchAssetsForAlbum(
        targetAlbum,
        pageSize: 40,
      );
      _deck = photos;
    } else {
      _deck = [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // swipe handler using ung package
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // if last na, simply return
    if (previousIndex >= _deck.length) return false;
    final photo = _deck[previousIndex];

    if (direction == CardSwiperDirection.left) {
      // swipe left to add sa deletion review
      setState(() {
        _stagedForDeletion.add(photo);
      });
    } else if (direction == CardSwiperDirection.right) {
      _fileToBinder(photo);
    } else if (direction == CardSwiperDirection.top) {
      _createTodoFromPhoto(photo);
    } else if (direction == CardSwiperDirection.bottom) {
      // skip if swipe down
    }

    return true;
  }

  Future<void> _openReviewTrashScreen() async {
    if (_stagedForDeletion.isEmpty) return;

    final remaining = await Navigator.of(context).push<List<AssetEntity>>(
      MaterialPageRoute(
        builder: (_) => ReviewTrashScreen(stagedPhotos: _stagedForDeletion),
      ),
    );

    if (mounted && remaining != null) {
      setState(() {
        _stagedForDeletion = remaining;
      });
    }
  }

  Future<void> _fileToBinder(AssetEntity photo) async {
    final binders = _binderController.allBinders;
    if (binders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No folders available. Create a folder first!'),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.folder_rounded, color: AppTheme.sage, size: 22),
            const SizedBox(width: 8),
            Text('Add to Folder', style: AppTheme.serifHeading(fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: binders.length,
            separatorBuilder: (_, _) =>
                const Divider(color: AppTheme.border, height: 1),
            itemBuilder: (context, index) {
              final b = binders[index];
              final color = ColorUtils.getColor(b.colorHex);
              return ListTile(
                leading: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  b.name,
                  style: AppTheme.sans(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _binderController.addPhotosToBinder(b.id, [photo.id]);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to ${b.name}'),
                        backgroundColor: AppTheme.sage,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _createTodoFromPhoto(AssetEntity photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateTodoScreen(initialAssetId: photo.id),
      ),
    );
  }

  // when you drag a bit to up down left right, a label will show
  Widget _buildDragOverlayBadge(int percentX, int percentY) {
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

  // since tinder style swiper is only portrait
  // pangit tignan if landscape yung photo
  // so we do something about it:
  Widget _buildPhotoContent(AssetEntity photo) {
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
            bottom: 24,
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

  //tinder card builder
  Widget _buildCard(AssetEntity photo, int percentX, int percentY) {
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
          Positioned.fill(child: _buildPhotoContent(photo)),

          //tap to preview fullscreen
          Positioned.fill(
            child: GestureDetector(
              onTap: () => PhotoUtils.openImageViewer(context, photo.id),
              behavior: HitTestBehavior.translucent,
            ),
          ),
          _buildDragOverlayBadge(percentX, percentY),
        ],
      ),
    );
  }

  void _showAlbumPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                'Select Album',
                style: AppTheme.serifHeading(fontSize: 18),
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _albums.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: AppTheme.borderSubtle, height: 1),
                itemBuilder: (context, index) {
                  final album = _albums[index];
                  final isSelected = album.id == _selectedAlbum?.id;

                  return ListTile(
                    leading: Icon(
                      Icons.folder_outlined,
                      color: isSelected
                          ? AppTheme.terracotta
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      album.name,
                      style: AppTheme.sans(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.terracotta
                            : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppTheme.terracotta,
                            size: 20,
                          )
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (album.id == _selectedAlbum?.id) return;

                      setState(() {
                        _selectedAlbum = album;
                        _isLoading = true;
                      });
                      final photos = await _photoService.fetchAssetsForAlbum(
                        album,
                        pageSize: 40,
                      );
                      if (mounted) {
                        setState(() {
                          _deck = photos;
                          _isLoading = false;
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Cleaner', style: AppTheme.serifHeading(fontSize: 22)),
            if (_deck.isNotEmpty)
              Text(
                '${_deck.length} to review',
                style: AppTheme.sans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          // if you have photos you wanted to delete, it is first staged in this trash review
          if (_stagedForDeletion.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: _openReviewTrashScreen,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.rose.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.rose.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.rose,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_stagedForDeletion.length}',
                        style: const TextStyle(
                          color: AppTheme.rose,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // you can pick which album to clean
          if (_albums.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: _showAlbumPickerSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 85),
                        child: Text(
                          _selectedAlbum?.name ?? 'Albums',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.sans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // reload button
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            tooltip: 'Reload Photos',
            onPressed: _loadAlbumsAndPhotos,
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.terracotta),
            )
          : _deck.isEmpty
          ? _buildEmptyState()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: 20,
                ),
                child: CardSwiper(
                  controller: _swiperController,
                  cardsCount: _deck.length,
                  numberOfCardsDisplayed: _deck.length >= 2 ? 2 : 1,
                  backCardOffset: const Offset(0, 16),
                  scale: 0.94,
                  isLoop: false,
                  padding: EdgeInsets.zero,
                  allowedSwipeDirection: const AllowedSwipeDirection.all(),
                  onSwipe: _onSwipe,
                  onEnd: () {
                    if (mounted) {
                      setState(() {
                        _deck.clear();
                      });
                      // If there are staged photos to delete, open review screen!
                      if (_stagedForDeletion.isNotEmpty) {
                        _openReviewTrashScreen();
                      }
                    }
                  },
                  cardBuilder: (context, index, percentX, percentY) {
                    return _buildCard(_deck[index], percentX, percentY);
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
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
          if (_stagedForDeletion.isNotEmpty)
            GestureDetector(
              onTap: _openReviewTrashScreen,
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
                      'Review ${_stagedForDeletion.length} Staged Photos',
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
            onTap: _loadAlbumsAndPhotos,
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

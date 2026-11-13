import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/controllers/cleaner_controller.dart';
import 'package:binder/models/binder.dart';
import 'package:binder/screens/cleaner/review_trash_screen.dart';
import 'package:binder/screens/todo/create_todo_screen.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/color_utils.dart';
import 'package:binder/widgets/album_picker_sheet.dart';
import 'package:binder/widgets/cleaner_card.dart';
import 'package:binder/widgets/cleaner_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CleanerScreen extends StatefulWidget {
  const CleanerScreen({super.key});

  @override
  State<CleanerScreen> createState() => _CleanerScreenState();
}

class _CleanerScreenState extends State<CleanerScreen> {
  final BinderController _binderController = BinderController();
  final CardSwiperController _swiperController = CardSwiperController();
  final CleanerController _cleanerController = CleanerController();

  bool _isLoading = true;
  int _topCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAlbumsAndPhotos();
  }

  @override
  void dispose() {
    _swiperController.dispose();
    _cleanerController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbumsAndPhotos() async {
    setState(() {
      _isLoading = true;
      _topCardIndex = 0;
    });
    await _cleanerController.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // scan using the ocr + do the text embedder cosine similarity ai
  void _triggerScan(AssetEntity photo) {
    if (_cleanerController.getScanResult(photo.id) != null ||
        _cleanerController.isScanning(photo.id)) {
      return;
    }
    _cleanerController.scanPhoto(photo).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  // swipe handler using ung package
  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    // if last na, simply return
    if (previousIndex >= _cleanerController.deck.length) return false;
    final photo = _cleanerController.deck[previousIndex];

    if (currentIndex != null) {
      setState(() {
        _topCardIndex = currentIndex;
      });
    }

    if (direction == CardSwiperDirection.left) {
      // swipe left to add sa deletion review
      setState(() {
        _cleanerController.stageForDeletion(photo);
      });
    } else if (direction == CardSwiperDirection.right) {
      _handleRightSwipe(photo);
    } else if (direction == CardSwiperDirection.top) {
      _createTodoFromPhoto(photo);
    } else if (direction == CardSwiperDirection.bottom) {
      // skip if swipe down
    }

    return true;
  }

  // handle saving in a binder when swiped right
  Future<void> _handleRightSwipe(AssetEntity photo) async {
    final scan = _cleanerController.getScanResult(photo.id);

    if (scan != null && scan.suggestedBinderId != null) {
      Binder? binder;
      for (final b in _binderController.allBinders) {
        if (b.id == scan.suggestedBinderId) {
          binder = b;
          break;
        }
      }
      if (binder != null) {
        await _cleanerController.fileToExistingBinder(binder.id, photo.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Auto-filed to ${binder.name}'),
              backgroundColor: AppTheme.sage,
              duration: const Duration(seconds: 1),
            ),
          );
        }
        return;
      }
    } else if (scan != null && scan.suggestedNewTopic != null) {
      final topic = scan.suggestedNewTopic!;
      final newBinder = await _cleanerController.createAndFileToRagTopic(
        topic,
        photo.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created & filed to ${newBinder.name}'),
            backgroundColor: AppTheme.sage,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    _fileToBinder(photo);
  }

  Future<void> _openReviewTrashScreen() async {
    if (_cleanerController.stagedForDeletion.isEmpty) return;

    final remaining = await Navigator.of(context).push<List<AssetEntity>>(
      MaterialPageRoute(
        builder: (_) => ReviewTrashScreen(
          stagedPhotos: _cleanerController.stagedForDeletion,
        ),
      ),
    );

    if (mounted && remaining != null) {
      setState(() {
        _cleanerController.updateStagedList(remaining);
      });
    }
  }

  // adding photo to the binder
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

  void _showAlbumPickerSheet() {
    AlbumPickerSheet.show(
      context: context,
      albums: _cleanerController.albums,
      selectedAlbum: _cleanerController.selectedAlbum,
      onAlbumSelected: (album) async {
        if (album.id == _cleanerController.selectedAlbum?.id) return;
        setState(() {
          _isLoading = true;
          _topCardIndex = 0;
        });
        await _cleanerController.switchAlbum(album);
        if (mounted) {
          setState(() => _isLoading = false);
        }
      },
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
            if (_cleanerController.deck.isNotEmpty)
              Text(
                '${_cleanerController.deck.length} to review',
                style: AppTheme.sans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          // if you have photos you wanted to delete, it is first staged in this trash review
          if (_cleanerController.stagedForDeletion.isNotEmpty)
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
                        '${_cleanerController.stagedForDeletion.length}',
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
          if (_cleanerController.albums.isNotEmpty)
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
                          _cleanerController.selectedAlbum?.name ?? 'Albums',
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
          : _cleanerController.deck.isEmpty
          ? CleanerEmptyState(
              stagedCount: _cleanerController.stagedForDeletion.length,
              onReviewTrash: _openReviewTrashScreen,
              onRefresh: _loadAlbumsAndPhotos,
            )
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
                  cardsCount: _cleanerController.deck.length,
                  numberOfCardsDisplayed: _cleanerController.deck.length >= 2
                      ? 2
                      : 1,
                  backCardOffset: const Offset(0, 16),
                  scale: 0.94,
                  isLoop: false,
                  padding: EdgeInsets.zero,
                  allowedSwipeDirection: const AllowedSwipeDirection.all(),
                  onSwipe: _onSwipe,
                  onEnd: () {
                    if (mounted) {
                      setState(() {
                        _cleanerController.clearDeck();
                      });
                      // If there are staged photos to delete, open review screen!
                      if (_cleanerController.stagedForDeletion.isNotEmpty) {
                        _openReviewTrashScreen();
                      }
                    }
                  },
                  cardBuilder: (context, index, percentX, percentY) {
                    final photo = _cleanerController.deck[index];
                    final isTop = index == _topCardIndex;
                    if (isTop) {
                      _triggerScan(photo);
                      if (index + 1 < _cleanerController.deck.length) {
                        _triggerScan(_cleanerController.deck[index + 1]);
                      }
                    }
                    return CleanerCard(
                      photo: photo,
                      percentX: percentX,
                      percentY: percentY,
                      isTop: isTop,
                      scanResult: _cleanerController.getScanResult(photo.id),
                      isScanning: _cleanerController.isScanning(photo.id),
                      binders: _binderController.allBinders,
                      onTapSuggestion: () => _fileToBinder(photo),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

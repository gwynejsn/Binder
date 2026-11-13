import 'package:binder/services/photo_service.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/photo_utils.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ReviewTrashScreen extends StatefulWidget {
  final List<AssetEntity> stagedPhotos;

  const ReviewTrashScreen({super.key, required this.stagedPhotos});

  @override
  State<ReviewTrashScreen> createState() => _ReviewTrashScreenState();
}

class _ReviewTrashScreenState extends State<ReviewTrashScreen> {
  final PhotoService _photoService = PhotoService();

  late List<AssetEntity> _photos;
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _photos = List<AssetEntity>.from(widget.stagedPhotos);
    //by default, select all staged photos for deletion
    for (final p in _photos) {
      _selectedIds.add(p.id);
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _photos.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (final p in _photos) {
          _selectedIds.add(p.id);
        }
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty || _isDeleting) return;

    setState(() => _isDeleting = true);

    final idsToDelete = _selectedIds.toList();
    final deleted = await _photoService.deleteAssetsFromDevice(idsToDelete);

    if (deleted && mounted) {
      // remove deleted photos from local list (sa in-memory)
      _photos.removeWhere((p) => idsToDelete.contains(p.id));
      _selectedIds.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${idsToDelete.length} photos removed from device'),
          backgroundColor: AppTheme.rose,
          duration: const Duration(seconds: 2),
        ),
      );

      //return remaining photos to CleanerScreen
      Navigator.pop(context, _photos);
    } else if (mounted) {
      setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool allSelected =
        _selectedIds.length == _photos.length && _photos.isNotEmpty;

    // we use popscope to pass again in the cleaner screen the photos we have selected to be staged!
    // https: //api.flutter.dev/flutter/widgets/PopScope-class.html
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _photos);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context, _photos),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review Trash', style: AppTheme.serifHeading(fontSize: 20)),
              Text(
                '${_selectedIds.length} of ${_photos.length} selected',
                style: AppTheme.sans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            if (_photos.isNotEmpty)
              TextButton(
                onPressed: _toggleSelectAll,
                child: Text(
                  allSelected ? 'Deselect All' : 'Select All',
                  style: const TextStyle(
                    color: AppTheme.terracotta,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: _photos.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  // photo grid nung mga idedelete
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                      itemCount: _photos.length,
                      itemBuilder: (context, index) {
                        final photo = _photos[index];
                        final bool isSelected = _selectedIds.contains(photo.id);

                        return GestureDetector(
                          onTap: () => _toggleSelection(photo.id),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.rose
                                    : AppTheme.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Thumbnail
                                AssetEntityImage(
                                  photo,
                                  isOriginal: false,
                                  thumbnailSize: const ThumbnailSize(300, 400),
                                  fit: BoxFit.cover,
                                ),

                                // dim overlay when not selected
                                if (!isSelected)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),

                                // checkbox icon badge
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.rose
                                          : Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                        : null,
                                  ),
                                ),

                                // Fullscreen inspect button (bottom right)
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () => PhotoUtils.openImageViewer(
                                      context,
                                      photo.id,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.fullscreen_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  //bottom action bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      border: Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                //clear selections and return keeping everything
                                Navigator.pop(context, <AssetEntity>[]);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Center(
                                  child: Text(
                                    'Keep All',
                                    style: AppTheme.sans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          //delete Selected
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: _selectedIds.isEmpty || _isDeleting
                                  ? null
                                  : _deleteSelected,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: _selectedIds.isEmpty
                                      ? AppTheme.border
                                      : AppTheme.rose,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isDeleting)
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.delete_forever_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedIds.isEmpty
                                          ? 'Select to Delete'
                                          : 'Delete (${_selectedIds.length})',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.sage.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.sage,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text('Trash is Empty', style: AppTheme.serifHeading(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            'All staged screenshots have been handled.',
            style: AppTheme.sans(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context, _photos),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Text(
                'Back to Cleaner',
                style: TextStyle(color: AppTheme.terracotta),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

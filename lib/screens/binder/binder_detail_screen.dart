import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/controllers/todo_controller.dart';
import 'package:binder/models/binder.dart';
import 'package:binder/models/todo_item.dart';
import 'package:binder/screens/binder/edit_binder_screen.dart';
import 'package:binder/screens/todo/create_todo_screen.dart';
import 'package:binder/screens/todo/todo_detail_screen.dart';
import 'package:binder/services/photo_service.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/color_utils.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class BinderDetailScreen extends StatefulWidget {
  final String binderId;

  const BinderDetailScreen({super.key, required this.binderId});

  @override
  State<BinderDetailScreen> createState() => _BinderDetailScreenState();
}

class _BinderDetailScreenState extends State<BinderDetailScreen> {
  final BinderController _binderController = BinderController();
  final TodoController _todoController = TodoController();

  late Binder _binder;
  String? _binderId;
  int _selectedTab = 0; // 0 = tasks, 1 = photos
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _binderId = widget.binderId;
    // pinasa natin from binders yung id ng selected binder
    _loadData();
  }

  Future<void> _loadData() async {
    if (_binderController.allBinders.isEmpty) {
      await _binderController.loadBinders();
    }
    await _todoController.loadTodos();
    // now we fetch based on that binder using the id
    // why fetch if we can just pass the binder? para when we go back
    // from editing, we can refetch again kasi baka may updates
    final found = _binderController.getBinderById(_binderId);
    if (found != null) {
      _binder = found;
    } else {
      // if not found, exit safely
      if (mounted) Navigator.pop(context);
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // navigates to the dedicated EditBinderScreen page
  Future<void> _openEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditBinderScreen(binder: _binder)),
    );

    // go back to binder screen if dinelete nating yung current binder
    if (result == 'deleted') {
      if (mounted) Navigator.pop(context);
    } else {
      _loadData();
    }
  }

  Future<void> _pickPhotosForBinder() async {
    final assets = await PhotoService().pickPhotos(context, maxAssets: 9);
    if (assets.isNotEmpty) {
      final ids = assets.map((a) => a.id).toList();
      await _binderController.addPhotosToBinder(_binder.id, ids);
      _loadData();
    }
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
    final folderColor = ColorUtils.getColor(_binder.colorHex);

    final binderTasks = _todoController.allTodos
        .where((t) => t.binderId == _binder.id)
        .toList();

    final allPhotos = List<String>.from(_binder.photoAssetIds);

    // also add photos attached from the todos
    for (final task in binderTasks) {
      for (final att in task.attachments) {
        if (!allPhotos.contains(att.assetId)) {
          allPhotos.add(att.assetId);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          // back arrow
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new, size: 18),
        ),
        actions: [
          // edit this binder button
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _openEditScreen,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // folder Info Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: folderColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: folderColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _binder.name,
                        style: AppTheme.serifHeading(fontSize: 22),
                      ),
                      if (_binder.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _binder.description,
                          style: AppTheme.sans(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${binderTasks.length} tasks • ${allPhotos.length} photos',
                        style: AppTheme.sans(
                          fontSize: 11,
                          color: AppTheme.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  // select tasks
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? AppTheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          'Tasks (${binderTasks.length})',
                          style: AppTheme.sans(
                            fontSize: 13,
                            fontWeight: _selectedTab == 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _selectedTab == 0
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  // select photos
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? AppTheme.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          'Photos (${allPhotos.length})',
                          style: AppTheme.sans(
                            fontSize: 13,
                            fontWeight: _selectedTab == 1
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: _selectedTab == 1
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // content photos area
          Expanded(
            child: _selectedTab == 0
                ? _buildTasksView(binderTasks)
                : _buildPhotosView(allPhotos),
          ),
        ],
      ),
      // Context-Aware Floating Button
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        backgroundColor: folderColor,
        foregroundColor: Colors.white,
        onPressed: () async {
          if (_selectedTab == 0) {
            // if selected tab is 0, go to create todo screen
            await Navigator.push(
              context,
              // we pass the binderId when coming from a binder from here in binder detail
              // to like auto select to this binder
              MaterialPageRoute(
                builder: (_) => CreateTodoScreen(initialBinderId: _binderId),
              ),
            );
            _loadData();
          } else {
            // else let users pick and add photos
            _pickPhotosForBinder();
          }
        },
        child: Icon(
          _selectedTab == 0 ? Icons.add : Icons.add_photo_alternate_outlined,
        ),
      ),
    );
  }

  Widget _buildTasksView(List<TodoItem> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'No tasks in this folder yet',
          style: AppTheme.sans(fontSize: 14, color: AppTheme.textTertiary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await _todoController.toggleComplete(task, !task.isCompleted);
                  _loadData();
                },
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted
                          ? AppTheme.sage
                          : AppTheme.textTertiary,
                      width: 1.5,
                    ),
                    color: task.isCompleted
                        ? AppTheme.sage
                        : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TodoDetailScreen(todo: task),
                      ),
                    );
                    _loadData();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: AppTheme.sans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: task.isCompleted
                              ? AppTheme.textTertiary
                              : AppTheme.textPrimary,
                        ),
                      ),
                      if (task.notes.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.sans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (task.attachments.isNotEmpty) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_outlined,
                      size: 14,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${task.attachments.length}',
                      style: AppTheme.sans(
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotosView(List<String> photos) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: 10),
            Text(
              'No photos in this folder yet',
              style: AppTheme.sans(fontSize: 14, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + below to add photos',
              style: AppTheme.sans(fontSize: 12, color: AppTheme.textTertiary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final assetId = photos[index];
        final isDirectPhoto = _binder.photoAssetIds.contains(assetId);

        return GestureDetector(
          // tapping of the image will make it viewable
          onTap: () => _openImageViewer(assetId),

          // long press will prompt if gusto idelete
          onLongPress: isDirectPhoto
              ? () => _confirmDeletePhoto(assetId)
              : null,

          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: FutureBuilder<AssetEntity?>(
              future: AssetEntity.fromId(assetId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.data != null) {
                  return AssetEntityImage(
                    snapshot.data!,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(250),
                    fit: BoxFit.cover,
                  );
                }
                return Container(color: AppTheme.surfaceElevated);
              },
            ),
          ),
        );
      },
    );
  }

  void _openImageViewer(String assetId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: FutureBuilder<AssetEntity?>(
                future: AssetEntity.fromId(assetId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return AssetEntityImage(
                      snapshot.data!,
                      isOriginal: true,
                      fit: BoxFit.contain,
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
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

  Future<void> _confirmDeletePhoto(String assetId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Photo?'),
        content: const Text(
          'Remove this photo from the folder? (The photo will stay in your phone gallery).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _binderController.deletePhotoFromBinder(_binder.id, assetId);
      _loadData();
    }
  }
}

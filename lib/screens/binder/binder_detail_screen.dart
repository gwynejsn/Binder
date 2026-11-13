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
import 'package:binder/widgets/todo_card.dart';
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

  // Multi-selection state for photos
  bool _isSelectionMode = false;
  final Set<String> _selectedPhotoIds = {};

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

  Future<void> _createTaskFromSelectedPhotos() async {
    if (_selectedPhotoIds.isEmpty) return;

    final selectedList = _selectedPhotoIds.toList();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTodoScreen(
          initialBinderId: _binder.id,
          initialAssetIds: selectedList,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedPhotoIds.clear();
      });
      if (result == true) {
        _loadData();
      }
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
        leading: _isSelectionMode && _selectedTab == 1
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedPhotoIds.clear();
                  });
                },
                child: const Icon(Icons.close_rounded, size: 22),
              )
            : GestureDetector(
                // back arrow
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
        title: _isSelectionMode && _selectedTab == 1
            ? Text(
                '${_selectedPhotoIds.length} Selected',
                style: AppTheme.sans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              )
            : null,
        actions: [
          // Select toggle in Photos tab
          if (_selectedTab == 1 && allPhotos.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  if (!_isSelectionMode) {
                    _isSelectionMode = true;
                  } else {
                    if (_selectedPhotoIds.length == allPhotos.length) {
                      _selectedPhotoIds.clear();
                      _isSelectionMode = false;
                    } else {
                      _selectedPhotoIds.addAll(allPhotos);
                    }
                  }
                });
              },
              child: Text(
                !_isSelectionMode
                    ? 'Select'
                    : (_selectedPhotoIds.length == allPhotos.length
                          ? 'Deselect All'
                          : 'Select All'),
                style: const TextStyle(
                  color: AppTheme.terracotta,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

          if (!_isSelectionMode)
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
                      if (_binder.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _binder.description,
                            style: AppTheme.sans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
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
                    onTap: () {
                      setState(() {
                        _selectedTab = 0;
                        _isSelectionMode = false;
                        _selectedPhotoIds.clear();
                      });
                    },
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
                : _buildPhotosView(allPhotos, folderColor),
          ),
        ],
      ),

      // Bottom bar for Multi-Selection task creation
      bottomNavigationBar: _isSelectionMode && _selectedTab == 1
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  border: const Border(top: BorderSide(color: AppTheme.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectedPhotoIds.isNotEmpty
                            ? _createTaskFromSelectedPhotos
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedPhotoIds.isNotEmpty
                                ? folderColor
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_task_rounded,
                                color: _selectedPhotoIds.isNotEmpty
                                    ? Colors.white
                                    : AppTheme.textTertiary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedPhotoIds.isNotEmpty
                                    ? 'Create Task (${_selectedPhotoIds.length})'
                                    : 'Select photos to create task',
                                style: TextStyle(
                                  color: _selectedPhotoIds.isNotEmpty
                                      ? Colors.white
                                      : AppTheme.textTertiary,
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
            )
          : null,

      // Context-Aware Floating Button (hidden during selection mode)
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
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
                      builder: (_) =>
                          CreateTodoScreen(initialBinderId: _binderId),
                    ),
                  );
                  _loadData();
                } else {
                  // else let users pick and add photos
                  _pickPhotosForBinder();
                }
              },
              child: Icon(
                _selectedTab == 0
                    ? Icons.add
                    : Icons.add_photo_alternate_outlined,
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

        return TodoCard(
          todo: task,
          showBinderTag:
              false, // Inside the folder, we don't need the folder badge
          onToggleComplete: (val) async {
            await _todoController.toggleComplete(task, val);
            _loadData();
          },
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TodoDetailScreen(todo: task)),
            );
            _loadData();
          },
          onDelete: () async {
            await _todoController.deleteTodo(task.id);
            _loadData();
          },
        );
      },
    );
  }

  Widget _buildPhotosView(List<String> photos, Color folderColor) {
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
      padding: EdgeInsets.fromLTRB(20, 10, 20, _isSelectionMode ? 80 : 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final assetId = photos[index];
        final isDirectPhoto = _binder.photoAssetIds.contains(assetId);
        final isSelected = _selectedPhotoIds.contains(assetId);

        return GestureDetector(
          // tapping of the image will make it viewable (or toggle selection)
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedPhotoIds.remove(assetId);
                  if (_selectedPhotoIds.isEmpty) {
                    _isSelectionMode = false;
                  }
                } else {
                  _selectedPhotoIds.add(assetId);
                }
              });
            } else {
              _openImageViewer(assetId);
            }
          },

          // long press will prompt if gusto idelete (or enter selection mode)
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedPhotoIds.add(assetId);
              });
            } else if (isDirectPhoto) {
              _confirmDeletePhoto(assetId);
            }
          },

          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? folderColor : AppTheme.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FutureBuilder<AssetEntity?>(
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

                if (isSelected)
                  Container(color: Colors.black.withValues(alpha: 0.35)),

                if (_isSelectionMode)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? folderColor : Colors.black54,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
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

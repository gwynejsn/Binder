import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/controllers/todo_controller.dart';
import 'package:binder/models/binder.dart';
import 'package:binder/screens/binder/binder_detail_screen.dart';
import 'package:binder/screens/binder/create_binder_screen.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class BindersScreen extends StatefulWidget {
  const BindersScreen({super.key});

  @override
  State<BindersScreen> createState() => _BindersScreenState();
}

class _BindersScreenState extends State<BindersScreen> {
  final BinderController _binderController = BinderController();
  final TodoController _todoController = TodoController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _binderController.loadBinders();
    await _todoController.loadTodos();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex));
    } catch (_) {
      return AppTheme.terracotta;
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

    final allBinders = _binderController.allBinders;
    final allTodos = _todoController.allTodos;

    final displayedBinders = _searchQuery.isEmpty
        ? allBinders
        : allBinders.where((b) {
            final query = _searchQuery.toLowerCase();
            return b.name.toLowerCase().contains(query) ||
                b.description.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text('Binders', style: AppTheme.serifHeading(fontSize: 22)),
        actions: [
          // add a new binder
          IconButton(
            icon: const Icon(
              Icons.create_new_folder_outlined,
              color: AppTheme.terracotta,
            ),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateBinderScreen()),
              );
              // if created, reload the binders
              if (created == true) {
                _loadData();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: AppTheme.sans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search binders...',
                hintStyle: AppTheme.sans(color: AppTheme.textTertiary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppTheme.textTertiary,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
          ),

          // 2-column grid sa mga binders
          Expanded(
            child: displayedBinders.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: displayedBinders.length,
                    itemBuilder: (context, index) {
                      final binder = allBinders[index];
                      final binderTasks = allTodos
                          .where((t) => t.binderId == binder.id)
                          .toList();

                      // count yung mga active todo inside each binder
                      final activeCount = binderTasks
                          .where((t) => !t.isCompleted)
                          .length;

                      // pagsamahin yung direct folder photos + photos attached from tasks/todos
                      final binderPhotos = <String>[...binder.photoAssetIds];
                      for (final task in binderTasks) {
                        for (final att in task.attachments) {
                          if (!binderPhotos.contains(att.assetId)) {
                            binderPhotos.add(att.assetId);
                          }
                        }
                      }

                      return _buildBinderCard(
                        binder,
                        binderPhotos,
                        activeCount,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBinderCard(
    Binder binder,
    List<String> photos,
    int activeTaskCount,
  ) {
    final color = _parseColor(binder.colorHex);

    return GestureDetector(
      onTap: () async {
        // clicking the card goes to the detailed screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BinderDetailScreen(binderId: binder.id),
          ),
        );
        // once it goes back, reload the data
        _loadData();
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // photo preview nung laman nung binder
            Expanded(child: _buildBoardCollage(photos, color)),
            const SizedBox(height: 10),

            // title
            Text(
              binder.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis, // put ellipsis if nag overflow
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),

            // photo count & active tasks
            Row(
              children: [
                Text(
                  '${photos.length} ${photos.length == 1 ? "photo" : "photos"}',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                if (activeTaskCount > 0) ...[
                  Text(
                    ' • ',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '$activeTaskCount active',
                    style: const TextStyle(
                      color: AppTheme.terracottaLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // parang pinterest where we have different collage depending on the
  // number of photos inside the binder

  Widget _buildBoardCollage(List<String> photos, Color color) {
    // 0 photos
    if (photos.isEmpty) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 36,
              color: color.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 6),
            Text(
              'Empty binder',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final topPhotos = photos.reversed.take(3).toList();

    // 1 photo
    if (topPhotos.length == 1) {
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox.expand(
          child: _buildThumb(topPhotos[0]),
        ), // <--- pass string directly
      );
    }

    // 2 photos
    if (topPhotos.length == 2) {
      return Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildThumb(topPhotos[0])),
            const SizedBox(width: 2.5),
            Expanded(child: _buildThumb(topPhotos[1])),
          ],
        ),
      );
    }

    // 3+ photos
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _buildThumb(topPhotos[0])),
          const SizedBox(width: 2.5),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildThumb(topPhotos[1])),
                const SizedBox(height: 2.5),
                Expanded(child: _buildThumb(topPhotos[2])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(String assetId) {
    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(assetId),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return AssetEntityImage(
            snapshot.data!,
            isOriginal: false,
            thumbnailSize: const ThumbnailSize.square(200),
            fit: BoxFit.cover,
          );
        }
        return Container(color: AppTheme.surfaceElevated);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 52,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matching binders found'
                : 'No binders yet',
            style: AppTheme.sans(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

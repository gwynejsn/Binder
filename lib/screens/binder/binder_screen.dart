import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/controllers/quick_pin_controller.dart';
import 'package:binder/controllers/todo_controller.dart';
import 'package:binder/models/binder.dart';
import 'package:binder/models/quick_reference_pin.dart';
import 'package:binder/screens/binder/binder_detail_screen.dart';
import 'package:binder/screens/binder/create_binder_screen.dart';
import 'package:binder/services/photo_service.dart';
import 'package:binder/theme/app_theme.dart';
import 'package:binder/utils/photo_utils.dart';
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
  final QuickPinController _quickPinController = QuickPinController();

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

  Future<void> _confirmDeletePin(QuickReferencePin pin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            const Icon(Icons.push_pin, size: 20, color: AppTheme.wheat),
            const SizedBox(width: 8),
            Text(
              'Unpin Reference?',
              style: AppTheme.serifHeading(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Remove "${pin.label}" from quick pins? (The photo will stay safe in your phone gallery).',
          style: AppTheme.sans(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unpin'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _quickPinController.deletePin(pin.id);
      setState(() {});
    }
  }

  Widget _buildQuickPinsSection() {
    final pins = _quickPinController.pins;
    if (pins.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: pins.length,
        itemBuilder: (context, index) {
          final pin = pins[index];

          return GestureDetector(
            onTap: () => PhotoUtils.openImageViewer(context, pin.assetId),
            onLongPress: () => _confirmDeletePin(pin),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    clipBehavior: Clip.antiAlias,
                    child: FutureBuilder<AssetEntity?>(
                      future: AssetEntity.fromId(pin.assetId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return AssetEntityImage(
                            snapshot.data!,
                            isOriginal: false,
                            thumbnailSize: const ThumbnailSize.square(100),
                            fit: BoxFit.cover,
                          );
                        }
                        return const Icon(
                          Icons.push_pin,
                          size: 12,
                          color: AppTheme.wheat,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pin.label,
                    style: AppTheme.sans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openAddQuickPinDialog() async {
    // pick 1 photo from phone gallery using PhotoService
    final assets = await PhotoService().pickPhotos(context, maxAssets: 1);
    if (assets.isEmpty) return;

    final asset = assets.first;
    final labelController = TextEditingController();

    if (!mounted) return;

    //aask user for a short name/label
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.push_pin_outlined,
              size: 20,
              color: AppTheme.wheat,
            ),
            const SizedBox(width: 8),
            Text('Quick Pin Label', style: AppTheme.serifHeading(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Give this reference photo a short name for 1-tap access at the top of your screen.',
              style: AppTheme.sans(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelController,
              autofocus: true,
              style: AppTheme.sans(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Class Schedule, Gym Pass, Wifi',
                hintStyle: AppTheme.sans(color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Pin Photo'),
          ),
        ],
      ),
    );

    // save the pin to SQLite
    if (save == true) {
      final label = labelController.text.trim();
      await _quickPinController.addPin(
        label: label.isEmpty ? 'Reference' : label,
        assetId: asset.id,
      );
      setState(() {}); // refresh so the new pin pill shows immediately!
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
          // quick pin add
          IconButton(
            icon: const Icon(Icons.push_pin_outlined, color: AppTheme.wheat),
            tooltip: 'Quick Pin Photo',
            onPressed: _openAddQuickPinDialog,
          ),
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
          SizedBox(height: 8),
          // quick pin
          _buildQuickPinsSection(),

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

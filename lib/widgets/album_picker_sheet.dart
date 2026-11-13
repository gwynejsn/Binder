import 'package:binder/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

// ito yung dropdown sa appbar ng cleaner to select albums to clean!
class AlbumPickerSheet extends StatelessWidget {
  final List<AssetPathEntity> albums;
  final AssetPathEntity? selectedAlbum;
  final ValueChanged<AssetPathEntity> onAlbumSelected;

  const AlbumPickerSheet({
    super.key,
    required this.albums,
    required this.selectedAlbum,
    required this.onAlbumSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required List<AssetPathEntity> albums,
    required AssetPathEntity? selectedAlbum,
    required ValueChanged<AssetPathEntity> onAlbumSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AlbumPickerSheet(
        albums: albums,
        selectedAlbum: selectedAlbum,
        onAlbumSelected: (album) {
          Navigator.pop(ctx);
          onAlbumSelected(album);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              itemCount: albums.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: AppTheme.borderSubtle, height: 1),
              itemBuilder: (context, index) {
                final album = albums[index];
                final isSelected = album.id == selectedAlbum?.id;

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
                  onTap: () => onAlbumSelected(album),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

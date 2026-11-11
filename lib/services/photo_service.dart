import 'package:binder/models/todo_attachment.dart';
import 'package:flutter/cupertino.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoService {
  static bool _hasPermission = false;
  bool get hasPermission => _hasPermission;

  // https://pub.dev/documentation/photo_manager/latest/#get-albumsfolders-assetpathentity
  Future<bool> requestPermissions() async {
    try {
      final state = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      _hasPermission = state.isAuth || state.hasAccess;
      return _hasPermission;
    } catch (e) {
      _hasPermission = false;
      return false;
    }
  }

  // this simply fetches the albums in your phone!
  // through this AssetPathEntity (album), we can get each AssetEntity (photo)
  Future<List<AssetPathEntity>> fetchAlbums() async {
    if (!_hasPermission) {
      await requestPermissions();
    }
    // fallback to return empty list if permission is still not granted
    if (!_hasPermission) return [];

    try {
      // https://pub.dev/documentation/photo_manager/latest/#using-with-filteroptiongroup
      final filter = FilterOptionGroup(
        imageOption: const FilterOption(
          needTitle: true,
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
        orders: [
          const OrderOption(type: OrderOptionType.createDate, asc: false),
        ],
      );

      // https://pub.dev/documentation/photo_manager/latest/#params-of-getassetpathlist
      return await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
        onlyAll: false,
        filterOption: filter,
      );
    } catch (e) {
      debugPrint('Error fetching albums: $e');
      return [];
    }
  }

  // fetches a page of photos (AssetEntity) inside an album (AssetPathEntity)
  Future<List<AssetEntity>> fetchAssetsForAlbum(
    AssetPathEntity album, {
    int page = 0,
    int pageSize = 60,
  }) async {
    try {
      return await album.getAssetListPaged(page: page, size: pageSize);
    } catch (e) {
      debugPrint('Error fetching photos: $e');
      return [];
    }
  }

  // earlier gamit natin is image_picker, but we switched to
  // https://pub.dev/packages/wechat_assets_picker
  // kasi same yung path na ginagamit ng photo_manager and wechat_assets_picker
  // which removes the bug kanina with paths!
  Future<List<TodoAttachment>> pickPhotos(
    BuildContext context, {
    int maxAssets = 5,
  }) async {
    final List<AssetEntity>? results = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: maxAssets,
        requestType: RequestType.image,
      ),
    );
    if (results == null || results.isEmpty) return [];
    return results.map((asset) => TodoAttachment(assetId: asset.id)).toList();
  }

  Future<bool> deleteAssetFromDevice(String assetId) async {
    try {
      final result = await PhotoManager.editor.deleteWithIds([assetId]);
      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error deleting asset: $e');
      return false;
    }
  }
}

import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';

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
}

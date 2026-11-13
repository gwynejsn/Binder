import 'package:binder/models/binder.dart';
import 'package:binder/repositories/binder_repository.dart';

class BinderController {
  final BinderRepository _repo = BinderRepository();
  // note we are storing the binders in-memory para mas mabilis ma access
  // parang caching or something
  static List<Binder> _binders = [];
  List<Binder> get allBinders => _binders;

  Future<List<Binder>> loadBinders() async {
    await _repo.seedBinders();
    _binders = await _repo.getBinders();
    return _binders;
  }

  Binder? getBinderById(String? id) {
    if (id == null) return null;
    for (final b in _binders) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<Binder> addBinder({
    required String name,
    String description = '',
    required String colorHex,
    String keywords = '',
  }) async {
    final newBinder = Binder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      colorHex: colorHex,
      createdAt: DateTime.now(),
      keywords: keywords,
      photoAssetIds: [],
    );

    await _repo.insertBinder(newBinder);
    _binders.add(newBinder);
    return newBinder;
  }

  Future<void> updateBinder(Binder updated) async {
    await _repo.updateBinder(updated);

    final index = _binders.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _binders[index] = updated;
    }
  }

  Future<void> deleteBinder(String id) async {
    await _repo.deleteBinder(id);
    _binders.removeWhere((b) => b.id == id);
  }

  Future<void> addPhotosToBinder(String binderId, List<String> assetIds) async {
    for (final assetId in assetIds) {
      await _repo.addPhoto(binderId, assetId);
    }

    // find the binder
    final index = _binders.indexWhere((b) => b.id == binderId);
    if (index != -1) {
      // if found, attach the photoIds
      final current = _binders[index];
      final updatedPhotos = List<String>.from(current.photoAssetIds)
        ..addAll(assetIds);
      _binders[index] = current.copyWith(photoAssetIds: updatedPhotos);
    }
  }

  Future<void> deletePhotoFromBinder(String binderId, String assetId) async {
    await _repo.deletePhoto(binderId, assetId);

    final index = _binders.indexWhere((b) => b.id == binderId);
    if (index != -1) {
      final current = _binders[index];
      final updatedPhotos = List<String>.from(current.photoAssetIds)
        ..remove(assetId);
      _binders[index] = current.copyWith(photoAssetIds: updatedPhotos);
    }
  }

  Future<void> deletePhotosFromBinder(
    String binderId,
    List<String> assetIds,
  ) async {
    for (final assetId in assetIds) {
      await _repo.deletePhoto(binderId, assetId);
    }

    final index = _binders.indexWhere((b) => b.id == binderId);
    if (index != -1) {
      final current = _binders[index];
      final updatedPhotos = List<String>.from(current.photoAssetIds)
        ..removeWhere((id) => assetIds.contains(id));
      _binders[index] = current.copyWith(photoAssetIds: updatedPhotos);
    }
  }
}

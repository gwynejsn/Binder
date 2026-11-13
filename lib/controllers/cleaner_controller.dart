import 'package:binder/controllers/binder_controller.dart';
import 'package:binder/controllers/todo_controller.dart';
import 'package:binder/models/binder.dart';
import 'package:binder/models/smart_scan_result.dart';
import 'package:binder/models/suggested_topic.dart';
import 'package:binder/services/ocr_service.dart';
import 'package:binder/services/photo_service.dart';
import 'package:flutter/foundation.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class CleanerController {
  final PhotoService _photoService = PhotoService();
  final OcrService _ocrService = OcrService();
  final BinderController _binderController = BinderController();
  final TodoController _todoController = TodoController();

  static List<AssetEntity> _deck = [];
  static List<AssetEntity> _stagedForDeletion = [];
  static List<AssetPathEntity> _albums = [];
  static AssetPathEntity? _selectedAlbum;

  static final Map<String, SmartScanResult> _scanCache = {};
  static final Set<String> _pendingScans = {};

  List<AssetEntity> get deck => _deck;
  List<AssetEntity> get stagedForDeletion => _stagedForDeletion;
  List<AssetPathEntity> get albums => _albums;
  AssetPathEntity? get selectedAlbum => _selectedAlbum;
  int get deckCount => _deck.length;
  int get stagedCount => _stagedForDeletion.length;

  Future<void> init() async {
    await _ocrService.init();
    await _binderController.loadBinders();
    await _todoController.loadTodos();
    await loadAlbumsAndPhotos();
  }

  Set<String> _getSavedAssetIds() {
    final Set<String> saved = {};
    for (final binder in _binderController.allBinders) {
      for (final id in binder.photoAssetIds) {
        saved.add(id);
      }
    }
    for (final todo in _todoController.allTodos) {
      for (final att in todo.attachments) {
        saved.add(att.assetId);
      }
    }
    return saved;
  }

  Future<void> loadAlbumsAndPhotos() async {
    _scanCache.clear();
    _pendingScans.clear();

    final fetchedAlbums = await _photoService.fetchAlbums();

    // prefer recent photos, or if no recent, then the first album
    AssetPathEntity? target;
    for (final a in fetchedAlbums) {
      if (a.name.toLowerCase().contains('recent')) {
        target = a;
        break;
      }
    }
    if (target == null && fetchedAlbums.isNotEmpty) {
      target = fetchedAlbums.first;
    }

    _albums = fetchedAlbums;
    _selectedAlbum = target;

    if (target != null) {
      final savedIds = _getSavedAssetIds();
      final rawAssets = await _photoService.fetchAssetsForAlbum(
        target,
        pageSize: 60,
      );
      _deck = rawAssets.where((asset) => !savedIds.contains(asset.id)).toList();
    } else {
      _deck = [];
    }
  }

  Future<void> switchAlbum(AssetPathEntity album) async {
    _selectedAlbum = album;
    _scanCache.clear();
    _pendingScans.clear();

    final savedIds = _getSavedAssetIds();
    final rawAssets = await _photoService.fetchAssetsForAlbum(
      album,
      pageSize: 60,
    );
    _deck = rawAssets.where((asset) => !savedIds.contains(asset.id)).toList();
  }

  void stageForDeletion(AssetEntity photo) {
    _stagedForDeletion.add(photo);
  }

  void updateStagedList(List<AssetEntity> updated) {
    _stagedForDeletion = updated;
  }

  Future<bool> executeBatchDelete() async {
    if (_stagedForDeletion.isEmpty) return false;

    final ids = _stagedForDeletion.map((p) => p.id).toList();
    final deleted = await _photoService.deleteAssetsFromDevice(ids);

    if (deleted) {
      _stagedForDeletion.clear();
      return true;
    }
    return false;
  }

  SmartScanResult? getScanResult(String photoId) => _scanCache[photoId];
  bool isScanning(String photoId) => _pendingScans.contains(photoId);

  Future<SmartScanResult?> scanPhoto(AssetEntity photo) async {
    if (_scanCache.containsKey(photo.id)) {
      return _scanCache[photo.id];
    }
    if (_pendingScans.contains(photo.id)) {
      return null;
    }

    _pendingScans.add(photo.id);

    try {
      final result = await _ocrService.scanAndAnalyze(
        photo,
        existingBinders: _binderController.allBinders,
      );
      _scanCache[photo.id] = result;
      return result;
    } catch (e) {
      debugPrint('Error scanning photo: $e');
      return null;
    } finally {
      _pendingScans.remove(photo.id);
    }
  }

  // put the photo to the binder
  Future<void> fileToExistingBinder(String binderId, String photoId) async {
    await _binderController.addPhotosToBinder(binderId, [photoId]);
  }

  // create a new binder based on the suggested topic
  Future<Binder> createAndFileToRagTopic(
    SuggestedTopic topic,
    String photoId,
  ) async {
    final newBinder = await _binderController.addBinder(
      name: topic.name,
      colorHex: topic.colorHex,
      keywords: topic.keywords,
      description: topic.description,
    );
    await _binderController.addPhotosToBinder(newBinder.id, [photoId]);
    return newBinder;
  }

  void clearDeck() {
    _deck.clear();
  }

  void dispose() {
    _ocrService.dispose();
  }
}

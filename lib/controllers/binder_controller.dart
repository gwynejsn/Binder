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
}

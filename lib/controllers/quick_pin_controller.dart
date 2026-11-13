import 'package:binder/models/quick_reference_pin.dart';
import 'package:binder/services/database_service.dart';

class QuickPinController {
  final DatabaseService _dbService = DatabaseService();
  static List<QuickReferencePin> _pins = [];
  List<QuickReferencePin> get pins => _pins;

  Future<List<QuickReferencePin>> loadPins() async {
    final db = await _dbService.getDatabase();
    final rows = await db.query('quick_pins', orderBy: 'created_at DESC');

    final List<QuickReferencePin> loaded = [];
    for (final row in rows) {
      loaded.add(
        QuickReferencePin(
          id: row['id'] as String,
          label: row['label'] as String,
          assetId: row['asset_id'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
        ),
      );
    }
    _pins = loaded;
    return _pins;
  }

  Future<void> addPin({required String label, required String assetId}) async {
    final db = await _dbService.getDatabase();
    final newPin = QuickReferencePin(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      assetId: assetId,
      createdAt: DateTime.now(),
    );

    await db.insert('quick_pins', {
      'id': newPin.id,
      'label': newPin.label,
      'asset_id': newPin.assetId,
      'created_at': newPin.createdAt.toIso8601String(),
    });

    _pins.insert(0, newPin);
  }

  Future<void> deletePin(String pinId) async {
    final db = await _dbService.getDatabase();
    await db.delete('quick_pins', where: 'id = ?', whereArgs: [pinId]);
    _pins.removeWhere((p) => p.id == pinId);
  }
}

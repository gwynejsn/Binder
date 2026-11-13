import 'package:binder/models/binder.dart';
import 'package:binder/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class BinderRepository {
  final DatabaseService _dbService = DatabaseService();

  // fetch all binders
  Future<List<Binder>> getBinders() async {
    final db = await _dbService.getDatabase();

    final List<Map<String, dynamic>> rows = await db.query(
      'binders',
      orderBy: 'created_at ASC',
    );

    final List<Binder> binders = [];

    for (final row in rows) {
      final binderId = row['id'] as String;

      // for each binder, fetch all the photos
      final photoRows = await db.query(
        'binder_photos',
        where: 'binder_id = ?',
        whereArgs: [binderId],
        orderBy: 'created_at ASC',
      );
      // attach their id's in the photoAssetsIds
      final photoAssetIds = photoRows
          .map((p) => p['asset_id'] as String)
          .toList();

      // we need to manually map again yung nasa db back to our model!
      binders.add(
        Binder(
          id: row['id'] as String,
          name: row['name'] as String,
          description: row['description'] as String? ?? '',
          colorHex: row['color_hex'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          keywords: row['keywords'] as String? ?? '',
          photoAssetIds: photoAssetIds,
        ),
      );
    }

    return binders;
  }

  // fetch single binder by ID
  Future<Binder?> getBinderById(String id) async {
    final db = await _dbService.getDatabase();

    final List<Map<String, dynamic>> rows = await db.query(
      'binders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.first;

    final photoRows = await db.query(
      'binder_photos',
      where: 'binder_id = ?',
      whereArgs: [id],
      orderBy: 'created_at ASC',
    );
    final photoAssetIds = photoRows
        .map((p) => p['asset_id'] as String)
        .toList();

    return Binder(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      colorHex: row['color_hex'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      keywords: row['keywords'] as String? ?? '',
      photoAssetIds: photoAssetIds,
    );
  }

  // save the photo assetId with the binderId in the db (make reference sa photo)
  Future<void> addPhoto(String binderId, String assetId) async {
    final db = await _dbService.getDatabase();
    await db.insert('binder_photos', {
      'binder_id': binderId,
      'asset_id': assetId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // delete from the db the photo reference
  Future<void> deletePhoto(String binderId, String assetId) async {
    final db = await _dbService.getDatabase();
    await db.delete(
      'binder_photos',
      where: 'binder_id = ? AND asset_id = ?',
      whereArgs: [binderId, assetId],
    );
  }

  // insert a new binder
  Future<void> insertBinder(Binder binder) async {
    final db = await _dbService.getDatabase();

    await db.insert('binders', {
      'id': binder.id,
      'name': binder.name,
      'description': binder.description,
      'color_hex': binder.colorHex,
      'created_at': binder.createdAt.toIso8601String(),
      'keywords': binder.keywords,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // update an existing binder
  Future<void> updateBinder(Binder binder) async {
    final db = await _dbService.getDatabase();

    await db.update(
      'binders',
      {
        'name': binder.name,
        'description': binder.description,
        'color_hex': binder.colorHex,
        'keywords': binder.keywords,
      },
      where: 'id = ?',
      whereArgs: [binder.id],
    );
  }

  //delete a binder safely (unlinks todos so tasks are not deleted)
  Future<void> deleteBinder(String id) async {
    final db = await _dbService.getDatabase();

    //detach any todos linked to this binder
    // we can put this in the todo repo for separation of concerns
    // pero tinatamad na ko :))
    await db.update(
      'todos',
      {'binder_id': null},
      where: 'binder_id = ?',
      whereArgs: [id],
    );

    // delete the binder record
    await db.delete('binders', where: 'id = ?', whereArgs: [id]);
  }

  // pre-populate initial default binders
  Future<void> seedBinders() async {
    final db = await _dbService.getDatabase();

    //only seed if table is currently empty
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM binders'),
    );
    if (count != null && count > 0) return;

    final defaultBinders = [
      Binder(
        id: 'b_school',
        name: 'Academics & Study',
        description: 'Homework, syllabus, and study materials',
        colorHex: '0xFF3B82F6',
        createdAt: DateTime.now(),
        keywords: 'canvas homework assignment study quiz exam problem set syllabus professor lecture due',
        photoAssetIds: [],
      ),
      Binder(
        id: 'b_receipts',
        name: 'Receipts & GCash',
        description: 'Payments, invoices, and transaction slips',
        colorHex: '0xFF10B981',
        createdAt: DateTime.now(),
        keywords: 'receipt payment total subtotal vat tax amount cashier php tender sale invoice change gcash card',
        photoAssetIds: [],
      ),
      Binder(
        id: 'b_tabs',
        name: 'Guitar Tabs',
        description: 'Chords, music sheets, and lyrics',
        colorHex: '0xFFEC4899',
        createdAt: DateTime.now(),
        keywords: 'guitar tabs chords capo fret tuning strumming acoustic song verse chorus tempo bpm tab',
        photoAssetIds: [],
      ),
      Binder(
        id: 'b_places',
        name: 'Food & Places',
        description: 'Recipes, restaurants, and spots to visit',
        colorHex: '0xFFF59E0B',
        createdAt: DateTime.now(),
        keywords: 'food recipe ingredients bake baking oven cooking restaurant cafe meal dish dining menu flour sugar butter',
        photoAssetIds: [],
      ),
    ];

    for (final binder in defaultBinders) {
      await insertBinder(binder);
    }
  }
}

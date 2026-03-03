import 'package:notetask_pro/core/database/database_helper.dart';
import 'package:notetask_pro/shared/models/models.dart';
import 'package:sqflite/sqflite.dart';

class RecordingDao {
  final DatabaseHelper _db;
  RecordingDao(this._db);

  Future<Database> get _database => _db.database;

  Future<void> insert(Recording recording) async {
    final db = await _database;
    await db.insert('recordings', recording.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('recordings', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Recording>> getForEntity(
      String entityId, String entityType) async {
    final db = await _database;
    final rows = await db.query(
      'recordings',
      where: 'entity_id = ? AND entity_type = ?',
      whereArgs: [entityId, entityType],
      orderBy: 'created_at ASC',
    );
    return rows.map(Recording.fromMap).toList();
  }
}

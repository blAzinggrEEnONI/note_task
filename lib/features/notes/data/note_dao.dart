import 'package:notetask_pro/core/database/database_helper.dart';
import 'package:notetask_pro/features/notes/domain/note.dart';
import 'package:notetask_pro/shared/models/models.dart';
import 'package:sqflite/sqflite.dart';

class NoteDao {
  final DatabaseHelper _db;
  NoteDao(this._db);

  Future<Database> get _database => _db.database;

  Future<void> insert(Note note) async {
    final db = await _database;
    await db.insert('notes', note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await _syncTags(db, note.id, note.tagIds);
  }

  Future<void> update(Note note) async {
    final db = await _database;
    await db.update('notes', note.toMap(),
        where: 'id = ?', whereArgs: [note.id]);
    await _syncTags(db, note.id, note.tagIds);
  }

  Future<void> delete(String id) async {
    final db = await _database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Note?> getById(String id) async {
    final db = await _database;
    final rows = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final note = Note.fromMap(rows.first);
    final tagIds = await _getTagIds(db, id);
    return note.copyWith(tagIds: tagIds);
  }

  Future<List<Note>> getAll({
    bool includeArchived = false,
    String? folderId,
    String? tagId,
    String? query,
  }) async {
    final db = await _database;

    String whereClause = includeArchived ? '' : 'is_archived = 0';
    final args = <dynamic>[];

    if (folderId != null) {
      whereClause += whereClause.isNotEmpty ? ' AND ' : '';
      whereClause += 'folder_id = ?';
      args.add(folderId);
    }

    if (query != null && query.isNotEmpty) {
      whereClause += whereClause.isNotEmpty ? ' AND ' : '';
      whereClause +=
          "(title LIKE ? OR content_plain LIKE ?)";
      args.addAll(['%$query%', '%$query%']);
    }

    List<Map<String, dynamic>> rows;

    if (tagId != null) {
      // Join through taggables
      rows = await db.rawQuery('''
        SELECT n.* FROM notes n
        INNER JOIN taggables t ON t.entity_id = n.id AND t.entity_type = 'note'
        ${whereClause.isNotEmpty ? 'WHERE t.tag_id = ? AND $whereClause' : 'WHERE t.tag_id = ?'}
        ORDER BY n.is_pinned DESC, n.updated_at DESC
      ''', [tagId, ...args]);
    } else {
      rows = await db.query(
        'notes',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: args.isNotEmpty ? args : null,
        orderBy: 'is_pinned DESC, updated_at DESC',
      );
    }

    final notes = <Note>[];
    for (final row in rows) {
      final note = Note.fromMap(row);
      final tagIds = await _getTagIds(db, note.id);
      notes.add(note.copyWith(tagIds: tagIds));
    }
    return notes;
  }

  Future<List<String>> _getTagIds(Database db, String noteId) async {
    final rows = await db.query('taggables',
        columns: ['tag_id'],
        where: "entity_id = ? AND entity_type = 'note'",
        whereArgs: [noteId]);
    return rows.map((r) => r['tag_id'] as String).toList();
  }

  Future<void> _syncTags(
      Database db, String noteId, List<String> tagIds) async {
    await db.delete('taggables',
        where: "entity_id = ? AND entity_type = 'note'",
        whereArgs: [noteId]);
    for (final tagId in tagIds) {
      await db.insert(
          'taggables',
          {
            'tag_id': tagId,
            'entity_id': noteId,
            'entity_type': 'note',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ---- Tags ----

  Future<List<AppTag>> getAllTags() async {
    final db = await _database;
    final rows = await db.query('tags', orderBy: 'name ASC');
    return rows.map(AppTag.fromMap).toList();
  }

  Future<void> insertTag(AppTag tag) async {
    final db = await _database;
    await db.insert('tags', tag.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteTag(String id) async {
    final db = await _database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Folders ----

  Future<List<AppFolder>> getAllFolders() async {
    final db = await _database;
    final rows = await db.query('folders', orderBy: 'name ASC');
    return rows.map(AppFolder.fromMap).toList();
  }

  Future<void> insertFolder(AppFolder folder) async {
    final db = await _database;
    await db.insert('folders', folder.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteFolder(String id) async {
    final db = await _database;
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Recordings ----

  Future<List<Recording>> getRecordings(String noteId) async {
    final db = await _database;
    final rows = await db.query('recordings',
        where: "entity_id = ? AND entity_type = 'note'",
        whereArgs: [noteId],
        orderBy: 'created_at ASC');
    return rows.map(Recording.fromMap).toList();
  }

  Future<void> insertRecording(Recording recording) async {
    final db = await _database;
    await db.insert('recordings', recording.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteRecording(String id) async {
    final db = await _database;
    await db.delete('recordings', where: 'id = ?', whereArgs: [id]);
  }
}

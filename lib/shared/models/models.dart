import 'package:uuid/uuid.dart';

class AppTag {
  final String id;
  final String name;
  final int? color;

  const AppTag({required this.id, required this.name, this.color});

  factory AppTag.create({required String name, int? color}) => AppTag(
        id: const Uuid().v4(),
        name: name,
        color: color,
      );

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'color': color};

  factory AppTag.fromMap(Map<String, dynamic> map) => AppTag(
        id: map['id'] as String,
        name: map['name'] as String,
        color: map['color'] as int?,
      );
}

class AppFolder {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;

  const AppFolder({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
  });

  factory AppFolder.create({required String name, String? parentId}) => AppFolder(
        id: const Uuid().v4(),
        name: name,
        parentId: parentId,
        createdAt: DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'parent_id': parentId,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory AppFolder.fromMap(Map<String, dynamic> map) => AppFolder(
        id: map['id'] as String,
        name: map['name'] as String,
        parentId: map['parent_id'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}

class Recording {
  final String id;
  final String filePath;
  final int? durationMs;
  final DateTime createdAt;
  final String entityId;
  final String entityType; // 'note' or 'task'

  const Recording({
    required this.id,
    required this.filePath,
    this.durationMs,
    required this.createdAt,
    required this.entityId,
    required this.entityType,
  });

  factory Recording.create({
    required String filePath,
    int? durationMs,
    required String entityId,
    required String entityType,
  }) =>
      Recording(
        id: const Uuid().v4(),
        filePath: filePath,
        durationMs: durationMs,
        createdAt: DateTime.now(),
        entityId: entityId,
        entityType: entityType,
      );

  Duration? get duration =>
      durationMs != null ? Duration(milliseconds: durationMs!) : null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'file_path': filePath,
        'duration_ms': durationMs,
        'created_at': createdAt.millisecondsSinceEpoch,
        'entity_id': entityId,
        'entity_type': entityType,
      };

  factory Recording.fromMap(Map<String, dynamic> map) => Recording(
        id: map['id'] as String,
        filePath: map['file_path'] as String,
        durationMs: map['duration_ms'] as int?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        entityId: map['entity_id'] as String,
        entityType: map['entity_type'] as String,
      );
}

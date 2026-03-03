import 'package:uuid/uuid.dart';

enum NotePriority { low, medium, high, urgent }

class Note {
  final String id;
  final String title;
  final String content; // Quill Delta JSON
  final String contentPlain;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? color;
  final bool isPinned;
  final bool isArchived;
  final String? folderId;
  final List<String> tagIds;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.contentPlain,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.isPinned = false,
    this.isArchived = false,
    this.folderId,
    this.tagIds = const [],
  });

  factory Note.create({
    String? title,
    String? content,
    String? contentPlain,
    int? color,
    String? folderId,
  }) {
    final now = DateTime.now();
    return Note(
      id: const Uuid().v4(),
      title: title ?? '',
      content: content ?? '',
      contentPlain: contentPlain ?? '',
      createdAt: now,
      updatedAt: now,
      color: color,
      folderId: folderId,
    );
  }

  Note copyWith({
    String? title,
    String? content,
    String? contentPlain,
    int? color,
    bool? isPinned,
    bool? isArchived,
    String? folderId,
    List<String>? tagIds,
    bool clearColor = false,
    bool clearFolder = false,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      contentPlain: contentPlain ?? this.contentPlain,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      color: clearColor ? null : (color ?? this.color),
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      tagIds: tagIds ?? this.tagIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'content_plain': contentPlain,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'color': color,
        'is_pinned': isPinned ? 1 : 0,
        'is_archived': isArchived ? 1 : 0,
        'folder_id': folderId,
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] as String,
        title: map['title'] as String,
        content: map['content'] as String,
        contentPlain: map['content_plain'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        color: map['color'] as int?,
        isPinned: (map['is_pinned'] as int) == 1,
        isArchived: (map['is_archived'] as int) == 1,
        folderId: map['folder_id'] as String?,
      );
}

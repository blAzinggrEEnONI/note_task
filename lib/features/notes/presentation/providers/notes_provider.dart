import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetask_pro/core/database/database_helper.dart';
import 'package:notetask_pro/features/notes/data/note_dao.dart';
import 'package:notetask_pro/features/notes/domain/note.dart';
import 'package:notetask_pro/shared/models/models.dart';

// ---- DAOs ----

final noteDaoProvider = Provider<NoteDao>(
    (ref) => NoteDao(DatabaseHelper.instance));

// ---- Notes list state ----

class NotesFilter {
  final String? folderId;
  final String? tagId;
  final String? query;
  final bool showArchived;

  const NotesFilter({
    this.folderId,
    this.tagId,
    this.query,
    this.showArchived = false,
  });

  NotesFilter copyWith({
    String? folderId,
    String? tagId,
    String? query,
    bool? showArchived,
    bool clearFolder = false,
    bool clearTag = false,
  }) =>
      NotesFilter(
        folderId: clearFolder ? null : (folderId ?? this.folderId),
        tagId: clearTag ? null : (tagId ?? this.tagId),
        query: query ?? this.query,
        showArchived: showArchived ?? this.showArchived,
      );
}

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NoteDao _dao;
  NotesFilter _filter = const NotesFilter();

  NotesNotifier(this._dao) : super(const AsyncValue.loading()) {
    _load();
  }

  NotesFilter get filter => _filter;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _dao.getAll(
        includeArchived: _filter.showArchived,
        folderId: _filter.folderId,
        tagId: _filter.tagId,
        query: _filter.query,
      );
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setFilter(NotesFilter filter) {
    _filter = filter;
    _load();
  }

  Future<void> createNote(Note note) async {
    await _dao.insert(note);
    _load();
  }

  Future<void> updateNote(Note note) async {
    await _dao.update(note);
    _load();
  }

  Future<void> deleteNote(String id) async {
    await _dao.delete(id);
    _load();
  }

  Future<void> togglePin(Note note) =>
      updateNote(note.copyWith(isPinned: !note.isPinned));

  Future<void> toggleArchive(Note note) =>
      updateNote(note.copyWith(isArchived: !note.isArchived));

  Future<void> refresh() => _load();
}

final notesProvider =
    StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>(
        (ref) => NotesNotifier(ref.watch(noteDaoProvider)));

// ---- Tags ----

final tagsProvider = FutureProvider<List<AppTag>>((ref) {
  return ref.watch(noteDaoProvider).getAllTags();
});

// ---- Folders ----

final foldersProvider = FutureProvider<List<AppFolder>>((ref) {
  return ref.watch(noteDaoProvider).getAllFolders();
});

// ---- Layout preference (grid vs list) ----

final noteLayoutProvider = StateProvider<bool>((ref) => false); // false = list

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notetask_pro/features/notes/domain/note.dart';
import 'package:notetask_pro/features/notes/presentation/providers/notes_provider.dart';
import 'package:notetask_pro/shared/models/models.dart';
import 'package:notetask_pro/shared/widgets/shared_widgets.dart';

class NotesListPage extends ConsumerStatefulWidget {
  const NotesListPage({super.key});

  @override
  ConsumerState<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends ConsumerState<NotesListPage> {
  final _searchController = TextEditingController();
  String? _selectedFolderId;
  String? _selectedTagId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    ref.read(notesProvider.notifier).setFilter(NotesFilter(
          folderId: _selectedFolderId,
          tagId: _selectedTagId,
          query: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final folders = ref.watch(foldersProvider);
    final tags = ref.watch(tagsProvider);
    final isGrid = ref.watch(noteLayoutProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            tooltip: isGrid ? 'List view' : 'Grid view',
            icon: Icon(isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () =>
                ref.read(noteLayoutProvider.notifier).state = !isGrid,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),

          // Folder / Tag chips row
          folders.when(
            data: (folderList) => tags.when(
              data: (tagList) => _buildFilterRow(folderList, tagList, cs),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Notes grid / list
          Expanded(
            child: notesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (notes) {
                if (notes.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.note_alt_outlined,
                    title: 'No notes yet',
                    subtitle: 'Tap + to create your first note',
                    action: FilledButton.icon(
                      onPressed: () => context.push('/notes/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('New Note'),
                    ),
                  );
                }
                return isGrid
                    ? _buildGrid(notes)
                    : _buildList(notes);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/notes/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
    );
  }

  Widget _buildFilterRow(
      List<AppFolder> folders, List<AppTag> tags, ColorScheme cs) {
    if (folders.isEmpty && tags.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: _selectedFolderId == null && _selectedTagId == null,
              onSelected: (_) {
                setState(() {
                  _selectedFolderId = null;
                  _selectedTagId = null;
                });
                _applyFilter();
              },
            ),
          ),
          for (final folder in folders)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: const Icon(Icons.folder_outlined, size: 14),
                label: Text(folder.name),
                selected: _selectedFolderId == folder.id,
                onSelected: (_) {
                  setState(() {
                    _selectedFolderId =
                        _selectedFolderId == folder.id ? null : folder.id;
                    _selectedTagId = null;
                  });
                  _applyFilter();
                },
              ),
            ),
          for (final tag in tags)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('#${tag.name}'),
                selected: _selectedTagId == tag.id,
                onSelected: (_) {
                  setState(() {
                    _selectedTagId =
                        _selectedTagId == tag.id ? null : tag.id;
                    _selectedFolderId = null;
                  });
                  _applyFilter();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(List<Note> notes) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _NoteCard(note: notes[i], isGrid: false),
    );
  }

  Widget _buildGrid(List<Note> notes) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: notes.length,
      itemBuilder: (context, i) => _NoteCard(note: notes[i], isGrid: true),
    );
  }
}

class _NoteCard extends ConsumerWidget {
  final Note note;
  final bool isGrid;
  const _NoteCard({required this.note, required this.isGrid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = note.color != null
        ? Color(note.color!).withOpacity(0.25)
        : cs.surfaceContainerLow;

    return GestureDetector(
      onTap: () => context.push('/notes/${note.id}/edit'),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.isPinned)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.push_pin, size: 14,
                      color: cs.primary.withOpacity(0.7)),
                ),
              if (note.title.isNotEmpty)
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (note.contentPlain.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note.contentPlain,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.65)),
                  maxLines: isGrid ? 4 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM d').format(note.updatedAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.45)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetask_pro/features/notes/domain/note.dart';
import 'package:notetask_pro/features/notes/presentation/providers/notes_provider.dart';
import 'package:notetask_pro/features/tasks/domain/task.dart';
import 'package:notetask_pro/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notetask_pro/shared/widgets/shared_widgets.dart';

class GlobalSearchPage extends ConsumerStatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  ConsumerState<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends ConsumerState<GlobalSearchPage> {
  final _searchController = TextEditingController();
  String _query = '';
  _FilterType _filter = _FilterType.all;

  List<Note> _noteResults = [];
  List<Task> _taskResults = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _noteResults = [];
        _taskResults = [];
        _query = '';
        _searching = false;
      });
      return;
    }
    setState(() {
      _query = q;
      _searching = true;
    });

    final dao = ref.read(noteDaoProvider);
    final taskDao = ref.read(taskDaoProvider);

    final notes = await dao.getAll(query: q);
    final tasks = await taskDao.getTopLevel(query: q);

    if (mounted) {
      setState(() {
        _noteResults = notes;
        _taskResults = tasks;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final showNotes = _filter == _FilterType.all || _filter == _FilterType.notes;
    final showTasks = _filter == _FilterType.all || _filter == _FilterType.tasks;

    final hasResults = _noteResults.isNotEmpty || _taskResults.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search notes and tasks...',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _search('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _FilterType.values.map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f.label),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
          ),

          // Results
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : _query.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search, size: 64,
                                color: cs.onSurface.withOpacity(0.2)),
                            const SizedBox(height: 12),
                            Text('Start typing to search',
                                style: TextStyle(
                                    color: cs.onSurface.withOpacity(0.4))),
                          ],
                        ),
                      )
                    : !hasResults
                        ? EmptyStateWidget(
                            icon: Icons.search_off,
                            title: 'No results',
                            subtitle: 'Nothing matched "$_query"',
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: [
                              if (showNotes && _noteResults.isNotEmpty) ...[
                                _SearchSectionHeader(
                                    icon: Icons.note_alt_outlined,
                                    label: 'Notes (${_noteResults.length})'),
                                ..._noteResults.map((n) => _NoteSearchTile(note: n, query: _query)),
                                const SizedBox(height: 16),
                              ],
                              if (showTasks && _taskResults.isNotEmpty) ...[
                                _SearchSectionHeader(
                                    icon: Icons.check_circle_outline,
                                    label: 'Tasks (${_taskResults.length})'),
                                ..._taskResults.map((t) => _TaskSearchTile(task: t, query: _query)),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

enum _FilterType {
  all('All'),
  notes('Notes'),
  tasks('Tasks');

  final String label;
  const _FilterType(this.label);
}

class _SearchSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SearchSectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(label,
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                      color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}

class _NoteSearchTile extends StatelessWidget {
  final Note note;
  final String query;
  const _NoteSearchTile({required this.note, required this.query});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.note_alt_outlined),
        title: Text(note.title.isEmpty ? '(Untitled)' : note.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: note.contentPlain.isNotEmpty
            ? Text(note.contentPlain, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12))
            : null,
        trailing: Text(DateFormat('MMM d').format(note.updatedAt),
            style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.45))),
        onTap: () => context.push('/notes/${note.id}/edit'),
      ),
    );
  }
}

class _TaskSearchTile extends StatelessWidget {
  final Task task;
  final String query;
  const _TaskSearchTile({required this.task, required this.query});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          task.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
          color: task.isCompleted ? Colors.green : null,
        ),
        title: Text(task.title,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
        subtitle: task.deadline != null
            ? Text(DateFormat('MMM d').format(task.deadline!),
                style: const TextStyle(fontSize: 12))
            : null,
        trailing: PriorityBadge(priority: task.priority, compact: true),
        onTap: () => context.push('/tasks/${task.id}'),
      ),
    );
  }
}

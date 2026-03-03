import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:notetask_pro/features/notes/domain/note.dart';
import 'package:notetask_pro/shared/models/models.dart';
import 'package:notetask_pro/features/notes/presentation/providers/notes_provider.dart';
import 'package:notetask_pro/features/notes/presentation/widgets/audio_recorder_widget.dart';
import 'package:notetask_pro/features/notes/presentation/widgets/audio_player_widget.dart';
import 'dart:convert';

class NoteEditorPage extends ConsumerStatefulWidget {
  final String? noteId;
  const NoteEditorPage({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends ConsumerState<NoteEditorPage> {
  late final QuillController _quillController;
  late final TextEditingController _titleController;
  final FocusNode _editorFocus = FocusNode();
  Note? _existingNote;
  bool _saving = false;
  String? _selectedFolderId;
  List<Recording> _recordings = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _quillController = QuillController.basic();
    _loadExistingNote();
  }

  Future<void> _loadExistingNote() async {
    if (widget.noteId == null) return;
    final dao = ref.read(noteDaoProvider);
    final note = await dao.getById(widget.noteId!);
    if (note != null && mounted) {
      setState(() {
        _existingNote = note;
        _titleController.text = note.title;
        _selectedFolderId = note.folderId;
      });
      if (note.content.isNotEmpty) {
        try {
          final doc = Document.fromJson(jsonDecode(note.content) as List);
          _quillController.document = doc;
        } catch (_) {
          // Fallback: treat as plain text
          _quillController.document =
              Document()..insert(0, note.contentPlain);
        }
      }
      // Load recordings
      final recordings = await dao.getRecordings(note.id);
      if (mounted) setState(() => _recordings = recordings);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final deltaJson =
        jsonEncode(_quillController.document.toDelta().toJson());
    final plainText = _quillController.document.toPlainText().trim();

    final dao = ref.read(noteDaoProvider);
    
    if (_existingNote == null) {
      final note = Note.create(
        title: _titleController.text.trim(),
        content: deltaJson,
        contentPlain: plainText,
        folderId: _selectedFolderId,
      );
      await ref.read(notesProvider.notifier).createNote(note);
      // Save recordings with the new note ID
      for (final recording in _recordings) {
        final updatedRecording = Recording.create(
          filePath: recording.filePath,
          entityId: note.id,
          entityType: 'note',
          durationMs: recording.durationMs,
        );
        await dao.insertRecording(updatedRecording);
      }
    } else {
      final updated = _existingNote!.copyWith(
        title: _titleController.text.trim(),
        content: deltaJson,
        contentPlain: plainText,
        folderId: _selectedFolderId,
      );
      await ref.read(notesProvider.notifier).updateNote(updated);
    }

    if (mounted) context.pop();
  }

  Future<void> _onRecordingComplete(String filePath) async {
    final recording = Recording.create(
      filePath: filePath,
      entityId: _existingNote?.id ?? 'temp',
      entityType: 'note',
    );
    setState(() => _recordings.add(recording));
    
    // If editing existing note, save immediately
    if (_existingNote != null) {
      final dao = ref.read(noteDaoProvider);
      await dao.insertRecording(recording);
    }
  }

  Future<void> _deleteRecording(Recording recording) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete recording?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _recordings.remove(recording));
      if (_existingNote != null) {
        final dao = ref.read(noteDaoProvider);
        await dao.deleteRecording(recording.id);
      }
    }
  }

  @override
  void dispose() {
    _quillController.dispose();
    _titleController.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final folders = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          folders.when(
            data: (folderList) => folderList.isEmpty
                ? const SizedBox.shrink()
                : PopupMenuButton<String?>(
                    icon: const Icon(Icons.folder_outlined),
                    tooltip: 'Set folder',
                    onSelected: (id) =>
                        setState(() => _selectedFolderId = id),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: null, child: Text('No folder')),
                      ...folderList.map((f) =>
                          PopupMenuItem(value: f.id, child: Text(f.name))),
                    ],
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Title field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _titleController,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            Divider(color: cs.outlineVariant, height: 16),

            // Quill toolbar
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: QuillSimpleToolbar(
                      controller: _quillController,
                      config: const QuillSimpleToolbarConfig(
                        showBoldButton: true,
                        showItalicButton: true,
                        showUnderLineButton: true,
                        showStrikeThrough: false,
                        showListBullets: true,
                        showListNumbers: true,
                        showCodeBlock: true,
                        showQuote: true,
                        showLink: true,
                        showHeaderStyle: true,
                        showSmallButton: false,
                        showInlineCode: false,
                        showColorButton: false,
                        showBackgroundColorButton: false,
                        showClearFormat: true,
                        showAlignmentButtons: false,
                        showIndent: false,
                        showUndo: true,
                        showRedo: true,
                        showFontFamily: false,
                        showFontSize: false,
                        showSearchButton: false,
                      ),
                    ),
                  ),
                ),
                AudioRecorderWidget(onRecordingComplete: _onRecordingComplete),
                const SizedBox(width: 8),
              ],
            ),

            Divider(color: cs.outlineVariant, height: 1),

            // Voice recordings section
            if (_recordings.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(color: cs.outlineVariant),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mic, size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Voice Recordings',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ..._recordings.map((rec) => AudioPlayerWidget(
                          recording: rec,
                          onDelete: () => _deleteRecording(rec),
                        )),
                  ],
                ),
              ),

            // Quill editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: QuillEditor.basic(
                  controller: _quillController,
                  focusNode: _editorFocus,
                  config: QuillEditorConfig(
                    placeholder: 'Start writing...',
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    autoFocus: widget.noteId == null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

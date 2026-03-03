import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:notetask_pro/features/notes/presentation/notes_list_page.dart';
import 'package:notetask_pro/features/notes/presentation/note_editor_page.dart';
import 'package:notetask_pro/features/tasks/presentation/tasks_list_page.dart';
import 'package:notetask_pro/features/tasks/presentation/task_detail_page.dart';
import 'package:notetask_pro/features/search/presentation/global_search_page.dart';
import 'package:notetask_pro/features/settings/settings_page.dart';
import 'package:notetask_pro/app/shell_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/notes',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        GoRoute(
          path: '/notes',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: NotesListPage()),
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TasksListPage()),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: GlobalSearchPage()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),
    // Full-screen routes (outside shell → no bottom nav)
    GoRoute(
      path: '/notes/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const NoteEditorPage(),
    ),
    GoRoute(
      path: '/notes/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          NoteEditorPage(noteId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/tasks/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          TaskDetailPage(taskId: state.pathParameters['id']!),
    ),
  ],
);

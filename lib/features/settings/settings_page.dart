import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notetask_pro/core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_mode') ?? 0;
    state = ThemeMode.values[index];
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }
}

// Expose for reading in main.dart
final themeModeProvider = _themeModeProvider;

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _defaultSoundPath;

  @override
  void initState() {
    super.initState();
    _loadSoundPath();
  }

  Future<void> _loadSoundPath() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _defaultSoundPath = prefs.getString('default_sound_path'));
  }

  Future<void> _pickSound() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('default_sound_path', path);
      if (!mounted) return;
      setState(() => _defaultSoundPath = path);
    }
  }

  Future<void> _clearSound() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('default_sound_path');
    if (!mounted) return;
    setState(() => _defaultSoundPath = null);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined, size: 16),
                    label: Text('Light')),
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_outlined, size: 16),
                    label: Text('Auto')),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined, size: 16),
                    label: Text('Dark')),
              ],
              selected: {themeMode},
              onSelectionChanged: (modes) =>
                  ref.read(themeModeProvider.notifier).setMode(modes.first),
            ),
          ),

          const SizedBox(height: 8),
          const _SectionHeader('Notifications'),

          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: const Text('Default reminder sound'),
            subtitle: Text(
              _defaultSoundPath == null
                  ? 'System default'
                  : _defaultSoundPath!.split('/').last,
              style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_defaultSoundPath != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Reset to default',
                    onPressed: _clearSound,
                  ),
                IconButton(
                  icon: const Icon(Icons.folder_open_outlined),
                  tooltip: 'Choose file',
                  onPressed: _pickSound,
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: const Text('Test notification'),
            subtitle: const Text('Send a test notification now', style: TextStyle(fontSize: 12)),
            trailing: TextButton(
              onPressed: () => NotificationService.showTestNotification(_defaultSoundPath),
              child: const Text('Test'),
            ),
          ),

          const SizedBox(height: 8),
          const _SectionHeader('About'),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('NoteTask Pro'),
            subtitle: Text('Version 1.0.0', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}

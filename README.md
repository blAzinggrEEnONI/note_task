# NoteTask Pro

NoteTask Pro is a comprehensive Notes & Task Manager app built with Flutter.

## Features

- **Notes Management**: Create, edit, and organize notes. Features rich text editing via `flutter_quill`.
- **Task Management**: Keep track of your to-dos and tasks efficiently.
- **Audio Recording**: Record and attach audio memos to your notes and tasks quickly.
- **Notifications**: Get timely reminders for your tasks using local notifications.
- **Local Storage**: Reliable offline first functionality using `sqflite`.

## Getting Started

This project is built using:
- Flutter
- `flutter_riverpod` for State Management
- `go_router` for Routing
- `sqflite` for Local Database

### Prerequisites
- Flutter SDK 3.5.0 or higher
- Android Studio / VS Code with Flutter extension
- A working Flutter environment setup

### Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/blAzinggrEEnONI/note_task.git
   ```
2. Navigate to the project directory:
   ```sh
   cd "Notes and task manager/notes_&_task_manager"
   ```
3. Get the dependencies:
   ```sh
   flutter pub get
   ```
4. Run the code generation (for Riverpod & Freezed):
   ```sh
   dart run build_runner build --delete-conflicting-outputs
   ```
5. Run the application:
   ```sh
   flutter run
   ```

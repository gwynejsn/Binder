# Binder

A modern, distraction-free productivity app built with **Flutter** and **SQLite**. Binder combines task management with camera roll decluttering: attach screenshots and photos to your tasks, and permanently purge them from your device's photo gallery once the task is marked as complete.

---

## Architecture Overview

The app follows a clean, decoupled MVC (Model-View-Controller) / Repository pattern:

```
lib/
├── models/         # Pure Dart data models (TodoItem, TodoAttachment, Enums)
├── repositories/   # SQLite database queries & persistence
├── services/       # Native device APIs (PhotoManager, DatabaseService)
├── controllers/    # In-memory caching, filtering, and business logic
├── screens/        # UI Views (TodoScreen, CreateTodoScreen, TodoDetailScreen)
└── utils/          # Helpers (FormatUtils, ColorUtils)
```

- **Persistence:** Local SQLite database via `sqflite` with foreign key constraints (`PRAGMA foreign_keys = ON`) and cascading deletes (`ON DELETE CASCADE`).
- **Filtering & Tabs:** Real-time in-memory filtering for `Active`, `Today`, and `Done` tasks with dynamic badge counts.

---

## Photo Management Deep Dive

### How `photo_manager` Works

Unlike standard file-based plugins, [`photo_manager`](https://pub.dev/packages/photo_manager) interacts directly with the operating system's native media layer:

- **iOS:** Communicates with Apple's **`PHPhotoLibrary`** (PhotoKit framework).
- **Android:** Communicates with Android's **`MediaStore`** provider.

### The Role of `assetId`

When a user selects a photo, the operating system assigns it a permanent native identifier: **`assetId`** (e.g., `9F4B1842-5B4A-483B-A94D-39F22B295842/L0/001`).

1. **Zero File Duplication:** The photo remains stored in the user's native **Camera Roll (Photos app)**. The app does not need to duplicate massive 15 MB image files into its private sandbox.
2. **Instant Rendering:** UI thumbnails are rendered via `AssetEntityImage` using `AssetEntity.fromId(assetId)` which loads downsampled, hardware-accelerated previews from the native gallery.
3. **Camera Roll Deletion:** When a task is marked complete, `photo_manager` calls:
   ```dart
   await PhotoManager.editor.deleteWithIds([assetId]);
   ```
   This triggers the official system confirmation dialog:
   > _"Allow 'Binder' to delete this photo from your photo library?"_
   > Upon confirmation, the screenshot is purged directly from the device's camera roll to reclaim actual physical storage.

---

## Why We Switched from `image_picker` to `wechat_assets_picker`

During development, photo attachments were initially implemented using Flutter's official `image_picker` plugin. However, this approach presented critical limitations:

### 1. The iOS `/tmp/` Directory Purge

- **The Problem:** `image_picker` places temporary copies of selected images inside the app sandbox's `/tmp/` directory.
- **The Consequence:** The iOS operating system is designed to automatically wipe everything inside `/tmp/` whenever an app terminates or system memory runs low. Reopening the app resulted in broken image links:
  ```
  PathNotFoundException: Cannot retrieve length of file (OS Error: No such file or directory, errno = 2)
  ```

### 2. iOS Container UUID Randomization

- **The Problem:** On iOS (both simulators and physical devices), every debug launch, rebuild, or app update assigns a **new random UUID** to the app sandbox:
  - _Build 1:_ `/Containers/Data/Application/62006AD3-3B68.../Documents/photo.png`
  - _Build 2:_ `/Containers/Data/Application/26ECB5C6-4702.../Documents/photo.png`
- **The Consequence:** Storing absolute file paths in SQLite broke image paths between runs because the old container UUID ceased to exist.

### 3. Inability to Delete Photos from Camera Roll

- **The Problem:** `image_picker` operates under strict iOS sandbox privacy boundaries. It only provides an isolated sandbox copy of an image.
- **The Consequence:** Deleting the local file copy freed a few kilobytes of app cache, but the original screenshot was left sitting in the user's iPhone Photos app. This defeated the core purpose of the app.

---

### The Solution: `wechat_assets_picker` (Built on `photo_manager`)

[`wechat_assets_picker`](https://pub.dev/packages/wechat_assets_picker) solved all three issues:

| Feature               | `image_picker`                                                | `wechat_assets_picker`                                                  |
| :-------------------- | :------------------------------------------------------------ | :---------------------------------------------------------------------- |
| **Photo Source**      | Ephemeral copied file in `/tmp/`                              | Native **`AssetEntity`** referencing the Apple Photos library           |
| **Database Storage**  | Heavy file paths (subject to UUID changes)                    | Lightweight, permanent **`assetId`**                                    |
| **Restart Stability** | Broken paths on reboot/rebuild                                | **100% immune** to app restarts and sandbox UUID changes                |
| **Gallery Deletion**  | Impossible (no system permission)                             | **Native Camera Roll Deletion** via `PhotoManager.editor.deleteWithIds` |
| **UI Boilerplate**    | Single-image picker only; requires custom UI for multi-select | Ready-to-use, multi-select gallery picker in **1 line of code**         |

---

## Multi-Task Deletion Safety Check

To prevent accidental data loss when multiple tasks reference the same screenshot, `TodoController` includes a safety guard before requesting deletion from the device:

```dart
// Check if any OTHER active task in the database is using this same photo
final isUsedInOtherTodo = _todos.any(
  (t) => t.id != todo.id && t.attachments.any((a) => a.assetId == att.assetId),
);

// Only delete from the iPhone Camera Roll if no other task needs it!
if (!isUsedInOtherTodo) {
  await photoService.deleteAssetFromDevice(att.assetId);
}
```

- If **Task A** and **Task B** share the same screenshot, completing **Task A** detaches the photo from Task A while safely keeping the physical image in the camera roll for Task B.
- The image is only purged once the last referencing task is completed.

---

## SQLite Database Schema

```sql
CREATE TABLE todos (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  notes TEXT,
  priority TEXT NOT NULL,
  deadline TEXT,
  binder_id TEXT,
  is_completed INTEGER NOT NULL DEFAULT 0,
  completed_pomodoros INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
);

CREATE TABLE todo_attachments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  todo_id TEXT NOT NULL,
  asset_id TEXT NOT NULL,
  FOREIGN KEY (todo_id) REFERENCES todos (id) ON DELETE CASCADE
);
```

---

## Getting Started

1. **Clone the repository and install dependencies:**

   ```bash
   flutter pub get
   ```

2. **iOS Setup:**
   Ensure photo library permissions are declared in `ios/Runner/Info.plist`:

   ```xml
   <key>NSPhotoLibraryUsageDescription</key>
   <string>Binder requires photo library access to attach and organize screenshots.</string>
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

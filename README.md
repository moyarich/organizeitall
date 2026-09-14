# OrganizeItAll

OrganizeItAll is a native iPhone and iPad task organizer built with **SwiftUI**, **SwiftData**, **Swift 6**, and a native **Material Design 3** design system.

The original repository was a 2020 UIKit/Core Data project. The current `main` branch contains a clean modern implementation with no UIKit view controllers, storyboards, Core Data model files, generated Core Data classes, or legacy image-button assets in the application target.

## Screenshot

<img src="docs/images/tasks-iphone.png" alt="OrganizeItAll Tasks screen on iPhone, showing search, filters, an Inbox task, and the New task button" width="360">

## Features

- Create, edit, and delete task lists.
- Create, edit, complete, reopen, and delete tasks.
- Keep unassigned tasks in **Inbox**.
- Move tasks between Inbox and lists.
- Low / Normal / High priority.
- Optional due dates and overdue indication.
- Search titles, notes, and list names.
- Filter tasks by **Open / All / Done**.
- Deleting a list preserves its tasks by moving them back to Inbox.
- Light and dark Material 3 color schemes.

## UI / design system

The interface uses an iOS-native Material Design 3 adaptation implemented directly in SwiftUI. There is no Android/Compose runtime and no third-party Material package.

The design system includes:

- Material 3 semantic color roles and light/dark schemes
- Material type-scale tokens using the system font
- Material shape tokens
- container cards and surfaces
- extended floating action buttons
- filter chips
- filled text fields
- search bars
- Material-style bottom navigation
- tonal metadata and action surfaces
- SF Symbols for platform-native iconography

## Stack

- SwiftUI app lifecycle (`@main App`)
- SwiftData (`@Model`, `@Query`, `ModelContext`)
- Swift 6 language mode with complete concurrency checking
- iOS / iPadOS 17.0+
- Swift Testing
- Material Design 3-inspired SwiftUI design system
- SF Symbols
- No third-party dependencies

## Project layout

```text
OrganizeItAll/
├── App/
│   ├── OrganizeItAllApp.swift
│   └── MainTabView.swift
├── DesignSystem/
│   ├── MaterialTheme.swift
│   └── MaterialComponents.swift
├── Models/
│   ├── TaskItem.swift
│   ├── TaskList.swift
│   └── TaskPriority.swift
├── Features/
│   ├── TaskLists/
│   │   ├── TaskListsView.swift
│   │   ├── TaskListDetailView.swift
│   │   ├── TaskListEditorView.swift
│   │   └── TaskListRow.swift
│   └── Tasks/
│       ├── TasksView.swift
│       ├── TaskEditorView.swift
│       ├── TaskRow.swift
│       └── TaskFilter.swift
└── Resources/
    └── Assets.xcassets/

OrganizeItAllTests/
├── TestModelContext.swift
├── TaskItemTests.swift
└── TaskListTests.swift

launch.sh                # Interactive launcher and terminal commands
OrganizeItAll.xcodeproj/  # Xcode project and shared scheme
```

## Quick start

### Requirements

- macOS with full Xcode installed (Swift 6 support).
- An iOS simulator runtime installed through Xcode, with an iPhone or iPad simulator running iOS 17 or later.
- `fzf` for the interactive menus. If you use Homebrew, install it with `brew install fzf`.

Apple's standalone Command Line Tools are not enough to build this iOS app.
There are no third-party app dependencies, servers, API keys, or environment files to configure. SwiftData creates the local database automatically.

```bash
git clone https://github.com/moyarich/organizeitall.git
cd organizeitall
./launch.sh
```

Choose **run**, then choose an iPhone or iPad simulator. The launcher boots the
simulator, waits for it to finish starting, builds the app, installs it, and opens it.
Type to filter either menu, press Enter to select, or Escape to cancel.

### Launcher commands

| Command | Action |
| --- | --- |
| `./launch.sh` or `./launch.sh menu` | Open the fzf action menu |
| `./launch.sh run` | Choose a simulator, build, and launch the app |
| `./launch.sh build` | Build for iOS Simulator without launching |
| `./launch.sh test` | Choose a simulator and run the tests |
| `./launch.sh devices` | List available simulators and their UUIDs |
| `./launch.sh xcode` | Open the project in Xcode |
| `./launch.sh help` | Show command usage |

To skip the simulator picker, copy a UUID from `./launch.sh devices` and pass it
as the second argument to `run` or `test`:

```bash
./launch.sh run SIMULATOR_UUID
./launch.sh test SIMULATOR_UUID
```

Replace `SIMULATOR_UUID` with an available iOS simulator's UUID. These direct
commands do not require fzf. Neither do `build`, `devices`, `xcode`, or `help`.

The launcher uses the selected full Xcode installation, falling back to
`/Applications/Xcode.app`. It does not change the Mac's global developer setting.
For Xcode installed elsewhere, set `DEVELOPER_DIR` explicitly:

```bash
DEVELOPER_DIR="/path/to/Xcode.app/Contents/Developer" ./launch.sh
```

Build products and test results go into the ignored `DerivedData/` folder.
The script resolves paths relative to its own location, so it can also be invoked
by its full path from another directory. Launching again restarts the app without
resetting its saved data.

### Run from Xcode

Run `./launch.sh xcode`, then:

1. Select the **OrganizeItAll** scheme.
2. Choose an iPhone or iPad simulator running iOS 17 or later.
3. Press **Command-R**.

### Tests

Run `./launch.sh test` to execute the Swift Testing suite. Its five tests cover
Inbox assignment, completion timestamps, priority sorting, list relationships,
and preserving tasks when a list is deleted. Tests use an in-memory SwiftData
store.

### Troubleshooting

- **fzf is missing:** Install it with `brew install fzf`, or use the direct commands above with a simulator UUID.
- **Full Xcode is missing:** Install and open Xcode to complete its setup. If it is outside `/Applications/Xcode.app`, provide `DEVELOPER_DIR` as shown above.
- **No iOS simulators are available:** Install an iOS runtime in Xcode Settings > Components and create a simulator in Xcode's Devices and Simulators window if needed.
- **An old simulator UUID no longer works:** Run `./launch.sh devices` and choose a currently available device.
- **First launch takes longer:** The simulator may need to complete its initial startup and data migration. The launcher waits for it before building and installing.

## Persistence

`TaskList` and `TaskItem` are SwiftData models. `TaskList.tasks` uses a nullify relationship rule, so deleting a list preserves its tasks and returns them to Inbox.

The old 2020 Core Data store is intentionally not part of the modern runtime. If importing historical user data ever becomes necessary, implement it as a bounded one-time migration tool instead of restoring Core Data as a permanent dependency.

## Developer guide

See [README-DEV.md](README-DEV.md) for architecture, Material 3 conventions, testing, persistence rules, and development commands.

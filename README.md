# OrganizeItAll

OrganizeItAll is a native iPhone and iPad task organizer built with **SwiftUI**, **SwiftData**, and **Swift 6**.

The original repository was a 2020 UIKit/Core Data project. The `modernize/swiftui-coredata` branch is a clean modern implementation: there are no UIKit view controllers, storyboards, Core Data model files, generated Core Data classes, or legacy image-button assets in the application target.

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

## Stack

- SwiftUI app lifecycle (`@main App`)
- SwiftData (`@Model`, `@Query`, `ModelContext`)
- Swift 6 language mode with complete concurrency checking
- iOS / iPadOS 17.0+
- Swift Testing
- SF Symbols
- No third-party dependencies

## Project layout

```text
OrganizeItAll/
├── App/
│   ├── OrganizeItAllApp.swift
│   └── MainTabView.swift
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
```

## Run the app

```bash
git clone https://github.com/moyarich/organizeitall.git
cd organizeitall
git switch modernize/swiftui-coredata
open OrganizeItAll.xcodeproj
```

In Xcode:

1. Select the **OrganizeItAll** scheme.
2. Choose an iPhone or iPad simulator running iOS 17 or later.
3. Press **Command-R**.

No server, environment file, package install, API key, or database setup is required. SwiftData creates the local store automatically.

### Terminal build

```bash
xcodebuild \
  -project OrganizeItAll.xcodeproj \
  -scheme OrganizeItAll \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

### Tests

List available simulators:

```bash
xcrun simctl list devices available
```

Then run:

```bash
xcodebuild test \
  -project OrganizeItAll.xcodeproj \
  -scheme OrganizeItAll \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

Replace the simulator name with one installed on your Mac.

## Persistence

`TaskList` and `TaskItem` are SwiftData models. `TaskList.tasks` uses a nullify relationship rule, so deleting a list preserves its tasks and returns them to Inbox.

The old 2020 Core Data store is intentionally not part of the modern runtime. If importing historical user data ever becomes necessary, implement it as a bounded one-time migration tool instead of restoring Core Data as a permanent dependency.

## Developer guide

See [README-DEV.md](README-DEV.md) for architecture, conventions, testing, and development commands.

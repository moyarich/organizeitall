# OrganizeItAll Developer Guide

This document describes the modern SwiftUI + SwiftData implementation on the `modernize/swiftui-coredata` branch.

Last reviewed: **September 2026**.

## Toolchain baseline

The project is intentionally straightforward and dependency-free.

- Xcode 26.6+ recommended
- Swift 6 language mode
- iOS / iPadOS deployment target: 17.0
- SwiftUI application lifecycle (`@main App`)
- SwiftData persistence
- XCTest unit tests

Xcode 27 was still a release candidate when this modernization pass was completed, so the project does not require Xcode 27-only APIs.

## Getting the source

```bash
git clone https://github.com/moyarich/organizeitall.git
cd organizeitall
git switch modernize/swiftui-coredata
```

Open the project:

```bash
open OrganizeItAll.xcodeproj
```

## Run locally

### Xcode

1. Open `OrganizeItAll.xcodeproj`.
2. Choose the `OrganizeItAll` scheme.
3. Pick any iOS 17+ iPhone/iPad simulator.
4. Press **Command-R**.

There are no package dependencies to resolve and no environment variables to configure.

### Command-line build

```bash
xcodebuild \
  -project OrganizeItAll.xcodeproj \
  -scheme OrganizeItAll \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

For a clean build:

```bash
xcodebuild \
  -project OrganizeItAll.xcodeproj \
  -scheme OrganizeItAll \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  clean build
```

### Run tests

List installed simulators first:

```bash
xcrun simctl list devices available
```

Then use one of those names:

```bash
xcodebuild test \
  -project OrganizeItAll.xcodeproj \
  -scheme OrganizeItAll \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

## Project layout

```text
OrganizeItAll/
├── OrganizeItAllApp.swift
├── RootView.swift
├── Assets.xcassets/
├── Models/
│   ├── TaskList.swift
│   └── TaskItem.swift
└── Features/
    ├── Lists/
    │   ├── ListsView.swift
    │   ├── ListDetailView.swift
    │   ├── ListEditorView.swift
    │   └── ListRow.swift
    └── Tasks/
        ├── TasksView.swift
        ├── TaskEditorView.swift
        └── TaskRow.swift

OrganizeItAllTests/
└── OrganizeItAllTests.swift
```

The feature filenames intentionally describe SwiftUI views rather than carrying over the old `*ViewController.swift` names.

## Application lifecycle

`OrganizeItAllApp` is the only application entry point:

```swift
@main
struct OrganizeItAllApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [TaskList.self, TaskItem.self])
    }
}
```

Attaching the model container at the scene establishes the shared SwiftData `ModelContext` used by `@Query` and `@Environment(\.modelContext)` throughout the app.

There is no `AppDelegate`, `SceneDelegate`, main storyboard, or Core Data stack.

## Model conventions

### `TaskList`

`TaskList` owns the to-many side of the relationship:

```swift
@Relationship(deleteRule: .nullify, inverse: \TaskItem.list)
var tasks: [TaskItem]
```

The nullify rule is deliberate. When a user deletes a list, its tasks remain useful and become Inbox tasks.

### `TaskItem`

A task can exist without a list:

```swift
var list: TaskList?
```

`nil` means **Inbox**.

Completion state is changed through `setCompleted(_:)` so `isCompleted`, `completedAt`, and `modifiedAt` stay synchronized.

Priority is persisted as an integer raw value. The UI works with the `TaskPriority` enum through the computed `priority` property. This keeps the persisted representation simple and explicit.

## SwiftData writes

Views get the context from the environment:

```swift
@Environment(\.modelContext) private var modelContext
```

The app explicitly calls `save()` after user-triggered mutations. SwiftData can autosave, but explicit saves make failure boundaries clearer for this small app and make the behavior easier to test.

When a save fails, the current implementation rolls the context back and triggers an assertion during development.

## Queries

Top-level screens use `@Query`:

```swift
@Query(sort: \TaskItem.modifiedAt, order: .reverse)
private var tasks: [TaskItem]
```

Search and the Open / All / Done filter are intentionally performed in memory because this is a small personal organizer. If the dataset becomes large, move those predicates into dynamic SwiftData fetch descriptors instead.

## Sorting

`TaskItem.displayOrder` keeps the UI ordering consistent:

1. Open tasks before completed tasks.
2. Higher priority first.
3. Earlier due dates first.
4. Most recently modified first.

Both the all-tasks screen and per-list screen use this ordering.

## Tests

The unit tests create an isolated in-memory SwiftData container for each test.

Current coverage verifies:

- list/task relationships
- Inbox behavior
- completion timestamps
- nullify behavior when deleting a list
- task priority ordering

When adding persistence behavior, add an in-memory test before relying on UI testing.

## Adding a new persisted property

SwiftData schema changes need deliberate migration planning once the app has real users.

For a simple optional/additive property:

1. Add the property to the relevant `@Model`.
2. Give it a safe default when appropriate.
3. Add a test using a fresh in-memory store.
4. Test upgrading an installed development build before release.

For destructive or semantic model changes, introduce a versioned SwiftData schema and migration plan rather than relying on an implicit migration.

## Legacy-data policy

The 2020 app stored data with Core Data. The modern app does not automatically open that old store.

Do **not** reintroduce Core Data as an application dependency just to preserve the old implementation. If an actual migration requirement appears, implement a bounded one-time importer into SwiftData.

## Before opening a PR

Run a simulator build, then unit tests on an installed simulator. Also verify manually:

- create/edit/delete a list
- create/edit/delete a task
- Inbox assignment
- move a task between Inbox and a list
- complete/reopen a task
- priority selection
- due-date display and overdue state
- search
- Open / All / Done filters
- deleting a list leaves its tasks in Inbox

## 2026 cleanup

The modernization removes the old project scaffolding:

- UIKit view controllers
- `AppDelegate` / `SceneDelegate` lifecycle
- `Main.storyboard`
- `LaunchScreen.storyboard` dependency
- Core Data stack
- `.xcdatamodeld`
- generated-style `+CoreDataClass` / `+CoreDataProperties` files
- iOS 13 deployment configuration
- legacy filenames that no longer described their contents

The Xcode project now reflects what the application actually is: a SwiftUI + SwiftData iOS 17+ app.

# OrganizeItAll Developer Guide

This guide describes the clean SwiftUI + SwiftData implementation on `modernize/swiftui-coredata`.

## Baseline

- SwiftUI application lifecycle
- SwiftData persistence
- Swift 6 language mode
- Complete concurrency checking
- iOS / iPadOS 17.0+
- Swift Testing
- No third-party dependencies

## Source structure

```text
OrganizeItAll/
├── App/                 # application entry point and top-level navigation
├── Models/              # persisted models and persisted value types
├── Features/
│   ├── TaskLists/       # list screens and components
│   └── Tasks/           # task screens, components, and filters
└── Resources/           # asset catalogs
```

Names describe their responsibility. Do not reintroduce legacy names such as `ViewController`, `CoreDataStack`, `List+CoreDataClass`, or generic names such as `RootView` when a more specific domain name is available.

## Application lifecycle

`OrganizeItAllApp` is the only app entry point. It attaches the SwiftData container at the scene level:

```swift
@main
struct OrganizeItAllApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [TaskList.self, TaskItem.self])
    }
}
```

There is no app delegate, scene delegate, storyboard, or Core Data stack.

## Models

### TaskList

`TaskList` owns the to-many relationship:

```swift
@Relationship(deleteRule: .nullify, inverse: \TaskItem.list)
var tasks: [TaskItem]
```

The nullify rule is intentional: deleting a task list makes its tasks Inbox items instead of deleting user data.

### TaskItem

A task's `list` is optional. `nil` means Inbox.

Use `setCompleted(_:)` instead of setting `isCompleted` directly so `completedAt` and `modifiedAt` remain synchronized.

### TaskPriority

`TaskPriority` is its own model value type. SwiftData persists its raw integer through `TaskItem.priorityRawValue`; UI code uses the computed `priority` property.

## Views

Feature folders should contain feature-specific SwiftUI views only.

- `TaskListsView` owns top-level list browsing.
- `TaskListDetailView` owns tasks for one list.
- `TaskListEditorView` owns create/edit list input.
- `TasksView` owns global task search/filtering.
- `TaskEditorView` owns create/edit task input.
- row views are small presentation components.

Keep navigation state close to the screen that owns it. Do not add coordinator/view-model layers unless state or behavior actually outgrows the view.

## SwiftData access

Top-level collections use `@Query`. Mutating views obtain the context from the environment:

```swift
@Environment(\.modelContext) private var modelContext
```

User-triggered mutations explicitly save. On failure, the context is rolled back in development so an invalid partial mutation is not silently retained.

For larger datasets, migrate in-memory search/filtering in `TasksView` to dynamic `FetchDescriptor` predicates.

## Tests

Tests use Swift Testing and an in-memory SwiftData container.

- `TaskItemTests.swift`: Inbox behavior, completion timestamps, sorting.
- `TaskListTests.swift`: relationships and nullify-on-delete behavior.
- `TestModelContext.swift`: shared isolated container factory.

Run tests with an installed simulator:

```bash
xcodebuild test \
  -project OrganizeItAll.xcodeproj \
  -scheme OrganizeItAll \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

## Build

```bash
xcodebuild \
  -project OrganizeItAll.xcodeproj \
  -scheme OrganizeItAll \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  clean build
```

## Persisted model changes

Once real users have SwiftData stores, schema changes require migration discipline.

For additive changes:

1. Add the property with a safe default or optional value.
2. Add model tests.
3. Test upgrading an installed development build.

For destructive or semantic changes, introduce a versioned SwiftData schema and migration plan.

Do not bring Core Data back into the runtime to support the 2020 implementation. If historical data must be imported, use a separate one-time migration path.

## Resource policy

Use SF Symbols for standard interface icons. Keep the asset catalog only for branded/custom artwork that is actually used. The current catalog contains the app icon only.

Do not add raster copies of system icons such as add, back, edit, trash, calendar, or checkmark icons.

## Before opening a PR

Verify:

- simulator build succeeds
- tests pass
- create/edit/delete list
- create/edit/delete task
- Inbox assignment
- move a task between Inbox and a list
- complete/reopen task
- priority behavior
- due date and overdue state
- search and Open / All / Done filters
- deleting a list preserves its tasks
- no new unused assets or misleading filenames were introduced

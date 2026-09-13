# OrganizeItAll Developer Guide

This guide describes the clean SwiftUI + SwiftData implementation on `modernize/swiftui-coredata`.

## Baseline

- SwiftUI application lifecycle
- SwiftData persistence
- Swift 6 language mode
- complete concurrency checking
- iOS / iPadOS 17.0+
- Swift Testing
- native Material Design 3 design system
- no third-party dependencies

## Source structure

```text
OrganizeItAll/
├── App/                 # app entry point and top-level navigation
├── DesignSystem/        # Material 3 tokens and reusable components
├── Models/              # persisted models and persisted value types
├── Features/
│   ├── TaskLists/       # list screens and presentation components
│   └── Tasks/           # task screens, presentation components, and filters
└── Resources/           # branded/custom assets only
```

Names describe responsibility. Do not reintroduce legacy names such as `ViewController`, `CoreDataStack`, `List+CoreDataClass`, or generic names such as `RootView` when a more specific domain name is available.

## Application lifecycle

`OrganizeItAllApp` is the only app entry point. It applies the Material theme at the root and attaches the SwiftData container at the scene level:

```swift
@main
struct OrganizeItAllApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .materialTheme()
        }
        .modelContainer(for: [TaskList.self, TaskItem.self])
    }
}
```

There is no app delegate, scene delegate, storyboard, or Core Data stack.

## Material Design 3

The Material implementation is intentionally native SwiftUI. Do not add an Android/Compose dependency or a third-party Material framework just to reproduce Material components.

### Theme tokens

`DesignSystem/MaterialTheme.swift` owns:

- semantic light/dark color roles
- type-scale tokens
- shape tokens
- the `materialColors` environment value
- the root `materialTheme()` modifier

Feature code should use semantic roles such as `primary`, `surfaceContainer`, `onSurfaceVariant`, and `errorContainer` rather than embedding arbitrary colors.

### Components

`DesignSystem/MaterialComponents.swift` owns reusable UI primitives currently needed by the app:

- `MaterialCard`
- `MaterialFloatingActionButton`
- `MaterialSearchBar`
- `MaterialFilterChip`
- `MaterialTextField`
- `MaterialMultilineField`
- `MaterialEmptyState`
- `MaterialNavigationBarItem`
- `MaterialSectionTitle`

Add a reusable component only when at least one product screen needs a stable Material behavior or visual contract. Avoid creating wrappers around every SwiftUI primitive.

### Platform adaptation

Material semantics are adapted to iOS rather than copied mechanically:

- system fonts are used with Material type-scale sizing instead of bundling Roboto
- SF Symbols are used for standard icons
- SwiftUI sheets, pickers, toggles, and date pickers retain native interaction behavior
- Material color, shape, surface, chip, field, FAB, and navigation hierarchy define the visual language

### Dark mode

`materialTheme()` chooses the light or dark Material color scheme from the SwiftUI `colorScheme` environment. Screens and reusable components should therefore consume semantic Material roles rather than branching on dark mode themselves.

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

Feature folders contain product-specific SwiftUI views only. Reusable visual primitives belong in `DesignSystem`.

- `TaskListsView` owns top-level list browsing.
- `TaskListDetailView` owns tasks for one list.
- `TaskListEditorView` owns create/edit/delete list input.
- `TasksView` owns global task search/filtering.
- `TaskEditorView` owns create/edit/delete task input.
- row views render domain content inside Material cards.

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

## Resource policy

Use SF Symbols for standard interface icons. Keep the asset catalog only for branded/custom artwork that is actually used.

Do not add raster copies of system icons such as add, back, edit, trash, calendar, folder, or checkmark icons.

## Before opening a PR

Verify:

- simulator build succeeds
- tests pass
- light and dark appearance both remain readable
- Material color roles are used instead of feature-local hard-coded colors
- create/edit/delete list
- create/edit/delete task
- Inbox assignment
- move a task between Inbox and a list
- complete/reopen task
- priority behavior
- due date and overdue state
- search and Open / All / Done filters
- deleting a list preserves its tasks
- no unused assets, duplicate design tokens, or misleading filenames were introduced

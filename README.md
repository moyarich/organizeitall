# OrganizeItAll

OrganizeItAll is a modern SwiftUI task organizer for iPhone and iPad. The original 2020 UIKit/Core Data school project has been resurrected as a SwiftUI + SwiftData application while keeping the original idea: organize tasks into lists, keep unfiled work in an Inbox, and quickly mark work complete.

## Modern stack

- SwiftUI for the application interface
- SwiftData for persistence
- `@Model` domain models with native relationships
- `ModelContainer` / `ModelContext` for storage and writes
- `@Query` for reactive list and task queries
- `NavigationStack`, `.searchable`, modern toolbars, and SF Symbols
- XCTest with an in-memory SwiftData container

SwiftData is the only application persistence layer. `NSManagedObject`, `NSPersistentContainer`, `@FetchRequest`, and managed-object contexts are no longer used by the app.

## Features

### Lists

Create and edit named lists with optional descriptions. Each list shows its open and total task counts. Selecting a list opens its tasks.

Deleting a list does **not** delete its tasks. SwiftData uses a nullify relationship rule, so those tasks move back to Inbox.

### Tasks

Create, edit, complete, reopen, and delete tasks. Tasks can belong to a list or remain unassigned in Inbox.

The Tasks tab includes:

- All / Open / Done filters
- native searchable task filtering
- search across title, notes, and list name
- quick completion toggles

## Data model

```text
List
├── id: UUID
├── name: String
├── detail: String
├── createdDate: Date
├── modifiedDate: Date
└── tasks: [Task]

Task
├── id: UUID
├── title: String
├── detail: String
├── isComplete: Bool
├── createdDate: Date
├── modifiedDate: Date
└── list: List?
```

`List.tasks` and `Task.list` are inverse SwiftData relationships. Deleting a list nullifies `Task.list`, preserving the task as an Inbox item.

## Requirements

- Xcode 15 or newer
- iOS 17 SDK or newer
- Swift 5.9+

The SwiftData experience is available on iOS 17 and later. The current legacy Xcode target still has an older deployment setting, so the scene bootstrap shows an upgrade message on older systems instead of attempting to initialize SwiftData.

## Running

1. Open `OrganizeItAll.xcodeproj` in Xcode.
2. Select the `OrganizeItAll` scheme.
3. Choose an iOS 17+ simulator or device.
4. Build and run.

No external packages or services are required.

## Persistence migration note

This modernization intentionally converts the project to SwiftData rather than retaining Core Data compatibility. Existing stores created by the 2020 Core Data build are not automatically imported into the new SwiftData store.

For this repository, that tradeoff keeps the codebase genuinely modern instead of carrying both persistence frameworks indefinitely. If production users with valuable legacy data are discovered, a separate one-time import utility can be added without making Core Data the ongoing application persistence layer.

## Next improvements

- Raise the Xcode project deployment target to iOS 17 and remove the pre-iOS-17 fallback bootstrap.
- Rename the remaining legacy source filenames left by the original Xcode project structure.
- Add due dates, priorities, reminders, and manual ordering.
- Add widgets and App Intents.
- Add optional CloudKit-backed SwiftData sync.

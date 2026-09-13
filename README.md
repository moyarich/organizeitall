# OrganizeItAll

OrganizeItAll is a native iOS task organizer built with SwiftUI and Core Data. The project began as a UIKit / storyboard class project in 2020 and has been modernized while preserving its original Core Data entities so existing local data can continue to load.

## What it does

- Create and edit named lists.
- Create tasks in a list or leave them in the Inbox.
- Mark tasks complete or incomplete.
- Search tasks by title, notes, or list name.
- Filter tasks by All, Open, or Done.
- Delete lists without deleting their tasks; orphaned tasks return to the Inbox.
- Persist everything locally with Core Data.

## Modernized architecture

```text
UIKit scene lifecycle
        |
        v
UIHostingController
        |
        v
SwiftUI
  |- ListsView
  |   |- ListDetailView
  |   |- ListEditorView
  |   `- TaskEditorView
  `- AllTasksView
        |
        v
NSManagedObjectContext
        |
        v
Core Data
  |- List
  `- Task
```

The app intentionally keeps the existing `List` and `Task` Core Data model instead of replacing persistence with SwiftData. That provides a safer migration path for data created by the original app.

## Key improvements

- Replaced the storyboard-driven task UI with SwiftUI.
- Fixed the old list screen, which incorrectly fetched and edited `Task` objects.
- Fixed generated model/property mismatches so Swift types match the `.xcdatamodel`.
- Replaced the repeatedly-created persistent container with one shared `NSPersistentContainer`.
- Added automatic lightweight migration settings and an in-memory store for tests.
- Added list/task navigation, search, filtering, empty states, accessibility labels, and modern SF Symbols.
- Added Core Data relationship tests.
- Removed the app's dependency on `Main.storyboard`; the launch storyboard is retained.

## Run the app

1. Open `OrganizeItAll.xcodeproj` in Xcode.
2. Select the `OrganizeItAll` scheme.
3. Choose an iPhone or iPad simulator.
4. Build and run with **Command-R**.
5. Run unit tests with **Command-U**.

No third-party dependencies are required.

## Data model

A `List` contains zero or more `Task` objects. A task may also have no list, in which case the UI presents it as an **Inbox** task. Deleting a list uses the existing nullify relationship behavior, so its tasks remain available instead of being destroyed.

## Next steps

Good follow-up improvements would be due dates and reminders, priorities, drag-and-drop ordering, widgets, iCloud/CloudKit sync, and a versioned Core Data model before adding new persisted fields.

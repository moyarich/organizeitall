# OrganizeItAll

OrganizeItAll is a small, native iPhone/iPad task organizer built with **SwiftUI** and **SwiftData**.

The repository started as a 2020 UIKit/Core Data school project. The `modernize/swiftui-coredata` branch has been rebuilt for modern Apple development while keeping the original idea: create lists, add tasks, keep unfiled tasks in Inbox, and finish work quickly.

> Last modernization pass: September 2026.

## What the app does

- Create, edit, and delete lists.
- Create, edit, complete, reopen, and delete tasks.
- Leave a task unassigned to keep it in **Inbox**.
- Assign tasks to lists.
- Set **Low / Normal / High** priority.
- Add an optional due date.
- See overdue tasks clearly.
- Search task titles, notes, and list names.
- Filter tasks by **Open / All / Done**.
- Preserve tasks when a list is deleted; they move back to Inbox.

## Current stack

- SwiftUI
- SwiftData
- Swift 6 language mode
- iOS / iPadOS 17.0+
- XCTest
- No third-party dependencies
- No storyboard-driven app lifecycle
- No Core Data model or `NSManagedObject` layer

## Requirements

For the 2026 toolchain:

- macOS with a supported Xcode installation
- **Xcode 26.6 or newer recommended**
- iOS 17.0+ simulator or device

As of September 2026, Xcode 26.6 is the current stable Xcode line and Xcode 27 is available as a release candidate. The project does not require beta software.

## Run the app in Xcode

```bash
git clone https://github.com/moyarich/organizeitall.git
cd organizeitall
git switch modernize/swiftui-coredata
open OrganizeItAll.xcodeproj
```

Then in Xcode:

1. Select the **OrganizeItAll** scheme.
2. Select an iPhone or iPad simulator running iOS 17 or later.
3. Press **Command-R** or click **Run**.

The app uses a local SwiftData store automatically. No server, API key, package install, database setup, or environment file is required.

### Run on a physical iPhone or iPad

1. Connect the device to your Mac.
2. Select the device as the run destination.
3. In **Signing & Capabilities**, choose your Apple development team if Xcode asks for one.
4. Press **Command-R**.

## Build from Terminal

A simulator build does not require choosing a particular installed simulator:

```bash
xcodebuild \
  -project OrganizeItAll.xcodeproj \
  -scheme OrganizeItAll \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

To see available simulator devices:

```bash
xcrun simctl list devices available
```

Run the unit tests by replacing the sample simulator name with one installed on your Mac:

```bash
xcodebuild test \
  -project OrganizeItAll.xcodeproj \
  -scheme OrganizeItAll \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

## Data model

```text
TaskList
├── id: UUID
├── name: String
├── notes: String
├── createdAt: Date
├── modifiedAt: Date
└── tasks: [TaskItem]

TaskItem
├── id: UUID
├── title: String
├── notes: String
├── isCompleted: Bool
├── createdAt: Date
├── modifiedAt: Date
├── completedAt: Date?
├── dueDate: Date?
├── priorityRawValue: Int
└── list: TaskList?
```

The relationship uses a **nullify** delete rule. Deleting a `TaskList` does not destroy its tasks; each task becomes an Inbox item instead.

## About the old Core Data version

This branch is intentionally **SwiftData-only**. It does not keep the old `.xcdatamodeld`, `NSPersistentContainer`, or `NSManagedObject` classes around as a permanent compatibility layer.

A Core Data store created by the original 2020 application is not automatically imported. If preserving real legacy user data becomes necessary, the right approach is a separate one-time importer rather than carrying two persistence architectures inside the application indefinitely.

## Developer documentation

See [readme-dev.md](readme-dev.md) for project structure, architecture, testing, persistence conventions, and development commands.

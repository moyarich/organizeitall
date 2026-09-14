# OrganizeItAll Developer Guide

This guide describes the clean SwiftUI + SwiftData implementation on `main`.

## Baseline

- SwiftUI application lifecycle
- SwiftData persistence
- Swift 6 language mode
- complete concurrency checking
- iOS / iPadOS 17.0+
- Swift Testing
- native Material Design 3 design system
- no third-party app dependencies

## Setup and launch

Use macOS with full Xcode supporting Swift 6 and an installed iOS simulator
runtime. Standalone Command Line Tools are insufficient. Install `fzf` for the
interactive menus (`brew install fzf` if you use Homebrew).

From the repository root:

```bash
chmod +x ./scripts/menu.sh
./scripts/menu.sh
```

Choose **run**, then an iPhone or iPad simulator running iOS 17 or later.
The launcher boots the selected device, waits for startup, builds, installs,
and opens the app. Type to filter, Enter to select, or Escape to cancel.
The combined menu also provides build, test, Xcode, and App Store actions.

| Command                       | Behavior                                     |
| ----------------------------- | -------------------------------------------- |
| `./scripts/launch.sh`         | Open the simulator development menu          |
| `./scripts/launch.sh run`     | Pick a simulator, build, install, and launch |
| `./scripts/launch.sh devices` | List available simulators and UUIDs          |
| `./scripts/launch.sh build`   | Build for iOS Simulator without launching    |
| `./scripts/launch.sh test`    | Pick a simulator and run tests               |
| `./scripts/launch.sh xcode`   | Open the Xcode project                       |
| `./scripts/launch.sh help`    | Show supported arguments                     |

For a direct run, replace `SIMULATOR_UUID` with a UUID from the device list:

```bash
./scripts/launch.sh run SIMULATOR_UUID
```

To run through Xcode,
open the project with the command above, select the **OrganizeItAll** scheme and
an iOS simulator, then press **Command-R**.

`.env` is used only by the publishing script; launching the
simulator app requires no credentials or environment configuration.

### Xcode selection and simulator setup

The launch script honors `DEVELOPER_DIR`, otherwise uses the selected full Xcode
installation or falls back to `/Applications/Xcode.app`. It does not change the
global `xcode-select` setting. For another installation:

```bash
DEVELOPER_DIR="/path/to/Xcode.app/Contents/Developer" ./scripts/menu.sh
```

If no devices are available, install an iOS runtime in Xcode Settings > Components
and create a device in Devices and Simulators if needed. Initial simulator
startup may take longer while its data migration completes.

## Build xcode project from cli

```bash
xcodebuild \
  -project OrganizeItAll.xcodeproj \
  -scheme OrganizeItAll \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  clean build
```

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

scripts/
├── menu.sh              # combined fzf menu
├── launch.sh            # simulator launch, build, and tests
└── publish.sh           # signed archive, IPA export, and upload
.env.example             # publishing configuration template
.env                     # local publishing settings; ignored by Git
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

Tests use Swift Testing and an in-memory SwiftData container. Keep them in
`OrganizeItAllTests/`, matching the Xcode test target and its source references;
a separate `tests/` folder is not needed.

- `TaskItemTests.swift`: Inbox behavior, completion timestamps, sorting precedence and ties, overdue boundaries, and persistence across model contexts.
- `TaskListTests.swift`: relationships, moving tasks between lists and Inbox, task deletion, open-task counts, and nullify-on-delete behavior.
- `TestModelContext.swift`: shared isolated container factory.

Run the simulator picker, or supply a device UUID to skip it:

```bash
./scripts/launch.sh test
# Or, replacing SIMULATOR_UUID with an available device UUID:
./scripts/launch.sh test SIMULATOR_UUID
```

The 13 tests run against an in-memory store. The shared context helper imports
`OrganizeItAll` with `@testable` so it can access the app's model types.

## Build

```bash
./scripts/launch.sh build
```

This builds the Debug configuration for a generic iOS Simulator destination with
code signing disabled. It does not produce an App Store archive. Simulator build
products and test results are under the ignored `DerivedData/` directory.

## App Store export and upload

Keep publishing settings in the repository-root `.env`. On a fresh checkout,
copy `.env.example` to `.env`; preserve any existing local configuration.
Fill in `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_KEY_PATH` using
an App Store Connect team API key with access to the app and signing resources.
The key path can be absolute or relative to the repository root. Set `APP_VERSION`
and increase `BUILD_NUMBER` for each upload of that version.

```bash
./scripts/publish.sh check
./scripts/publish.sh export
./scripts/publish.sh upload
```

- `check` validates local configuration and Xcode availability. It does not verify Apple account access, signing, or build-number availability. This is also the default action.
- `export` archives a signed Release build for iOS devices and exports an App Store IPA.
- `upload` archives a fresh signed Release build and uploads it to App Store Connect. Selecting **upload** in the fzf menu runs this same action.

Export and upload permit Xcode to update provisioning resources and require
Apple Developer membership, signing access, and a matching App Store Connect
app record for `com.moyarich.OrganizeItAll`. Each run stores artifacts in its own
folder under `build/app-store/`. The script uses the configured version and build
number without editing the project file.

`.env` is sourced as trusted local shell configuration. It and private signing
files are ignored by Git; only the blank `.env.example` should be shared.
The launcher inherits `DEVELOPER_DIR` from direnv; publishing also reads `.env` directly.

Uploading does not submit for App Review or release the app publicly. After
processing, finish the listing, screenshots, privacy and compliance details,
select the build, and submit it in App Store Connect. See the
[README publishing guide](../README.md#publish-to-app-store-connect) for setup details.

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

## Close the app

On iPhone/iPad or its simulator, swipe up from the bottom edge and pause to open
App Switcher, then swipe the OrganizeItAll card upward. On devices with a Home
button, double-click Home to open App Switcher. Going to the Home Screen alone
leaves the app in the background.

For a simulator, choose **stop** in `./scripts/menu.sh`, or run:

```bash
./scripts/launch.sh stop
```

This closes OrganizeItAll on booted simulators without deleting saved tasks.
Pass a simulator UUID after `stop` to target one device. **quit** only exits the
terminal menu. To close the Simulator desktop application itself, use Command-Q
while Simulator is active.

## Swift package model tests

`Package.swift` builds the shared sources in `OrganizeItAll/Models` and runs
`OrganizeItAllTests` directly on macOS 14 or later with Swift 6:

```bash
./scripts/test.sh
```

The script selects full Xcode automatically without changing global settings and
uses a separate package build directory. Choose **models** in the fzf menu for
the same tests. To run Swift directly with full Xcode, use:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

The package covers models and persistence tests. Use `./scripts/menu.sh` and
`OrganizeItAll.xcodeproj` for the iOS interface, simulator launch, app icon,
signing, and App Store publishing. `swift run` does not launch the iPhone app.

If plain `swift test` reports `SwiftDataMacros` plugin errors, the selected
Command Line Tools do not provide the required macro plugin. Use
`./scripts/test.sh` instead. Do not remove SwiftData annotations to work around
a toolchain selection error.

## direnv: use plain swift test

The project uses `.env` directly; no `.envrc` is needed. Starting
`./scripts/menu.sh` automatically runs `scripts/setup.sh`, which installs direnv
through Homebrew if missing, enables native `.env` discovery in your user-level
`direnv.toml`, creates `.env` from `.env.example` if needed, and allows it.
Existing `.env` values are preserved. Set `DEVELOPER_DIR` to your full Xcode
installation; the default is `/Applications/Xcode.app/Contents/Developer`.

Direnv loads all `.env` settings, including any publishing credentials, into the
project shell and restores the previous environment when you leave. `.env`
remains ignored by Git. Native `.env` discovery also applies to other directories;
each environment still needs direnv authorization.

If your shell does not already enable direnv, add this line to `~/.zshrc` once:

```bash
eval "$(direnv hook zsh)"
```

Open a new terminal, enter this repository, then run:

```bash
./scripts/setup.sh
swift test
```

Without the shell hook, use `direnv exec . swift test`. After editing `.env`, run
`direnv allow .env` to approve the updated settings.

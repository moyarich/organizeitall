# OrganizeItAll

OrganizeItAll is a native iPhone and iPad task organizer built with **SwiftUI**, **SwiftData**, **Swift 6**, and a native **Material Design 3** design system.

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
├── DesignSystem/
├── Models/
├── Features/
│   ├── TaskLists/
│   └── Tasks/
└── Resources/
OrganizeItAllTests/

scripts/
├── menu.sh              # Unified fzf menu
├── launch.sh            # Simulator launch, build, and tests
└── publish.sh           # App Store export and upload
OrganizeItAll.xcodeproj/  # Xcode project and shared scheme
```

## Quick start

### Requirements

- macOS with full Xcode installed (Swift 6 support).
- An iOS simulator runtime installed through Xcode, with an iPhone or iPad simulator running iOS 17 or later.
- `fzf` for the interactive menus. If you use Homebrew, install it with `brew install fzf`.

Apple's standalone Command Line Tools are not enough to build this iOS app.
There are no third-party app dependencies, servers, API keys, or environment files to configure. SwiftData creates the local database automatically.

### define the active developer directory for your Mac's xcode command-line tools

sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

```bash
git clone https://github.com/moyarich/organizeitall.git
cd organizeitall
./scripts/menu.sh
```

Choose **run**, then choose an iPhone or iPad simulator. The launcher boots the
simulator, waits for it to finish starting, builds the app, installs it, and opens it.
Type to filter either menu, press Enter to select, or Escape to cancel.

### Launcher commands

Run `./scripts/menu.sh` for the combined fzf menu: launch, build, test, list
simulators, open Xcode, check publishing settings, export an IPA, or upload to
App Store Connect. Selecting **upload** starts the publishing workflow.
The `.env` file stays in the repository root.

| Command                                             | Action                                        |
| --------------------------------------------------- | --------------------------------------------- |
| `./scripts/launch.sh` or `./scripts/launch.sh menu` | Open the fzf action menu                      |
| `./scripts/launch.sh run`                           | Choose a simulator, build, and launch the app |
| `./scripts/launch.sh build`                         | Build for iOS Simulator without launching     |
| `./scripts/launch.sh test`                          | Choose a simulator and run the tests          |
| `./scripts/launch.sh devices`                       | List available simulators and their UUIDs     |
| `./scripts/launch.sh xcode`                         | Open the project in Xcode                     |
| `./scripts/launch.sh help`                          | Show command usage                            |

To skip the simulator picker, copy a UUID from `./scripts/launch.sh devices` and pass it
as the second argument to `run` or `test`:

```bash
./scripts/launch.sh run SIMULATOR_UUID
./scripts/launch.sh test SIMULATOR_UUID
```

Replace `SIMULATOR_UUID` with an available iOS simulator's UUID. These direct
commands do not require fzf. Neither do `build`, `devices`, `xcode`, or `help`.

The launcher uses the selected full Xcode installation, falling back to
`/Applications/Xcode.app`. It does not change the Mac's global developer setting.
For Xcode installed elsewhere, set `DEVELOPER_DIR` explicitly:

```bash
DEVELOPER_DIR="/path/to/Xcode.app/Contents/Developer" ./scripts/launch.sh
```

Build products and test results go into the ignored `DerivedData/` folder.
The script resolves paths relative to its own location, so it can also be invoked
by its full path from another directory. Launching again restarts the app without
resetting its saved data.

### Run from Xcode

Run `./scripts/launch.sh xcode`, then:

1. Select the **OrganizeItAll** scheme.
2. Choose an iPhone or iPad simulator running iOS 17 or later.
3. Press **Command-R**.

### Tests

Run `./scripts/launch.sh test` to execute the Swift Testing suite. Its 13 tests cover
Inbox assignment, completion timestamps, priority sorting, list relationships,
overdue boundaries, saved edits, moving tasks, task deletion, open-task counts,
and preserving tasks when a list is deleted. Tests use an in-memory SwiftData
store.

### Troubleshooting

- **fzf is missing:** Install it with `brew install fzf`, or use the direct commands above with a simulator UUID.
- **Full Xcode is missing:** Install and open Xcode to complete its setup. If it is outside `/Applications/Xcode.app`, provide `DEVELOPER_DIR` as shown above.
- **No iOS simulators are available:** Install an iOS runtime in Xcode Settings > Components and create a simulator in Xcode's Devices and Simulators window if needed.
- **An old simulator UUID no longer works:** Run `./scripts/launch.sh devices` and choose a currently available device.
- **First launch takes longer:** The simulator may need to complete its initial startup and data migration. The launcher waits for it before building and installing.

## Publish to App Store Connect

Use `scripts/publish.sh` to archive a Release build and export or upload it with Xcode.
This requires an Apple Developer Program membership, a registered bundle ID
`com.moyarich.OrganizeItAll`, and a matching app record in App Store Connect.
Your account must have access to distribution signing certificates and profiles.
The script allows Xcode to create or update signing resources automatically.

1. Copy `.env.example` to `.env` if the local file does not already exist.
2. Fill in `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_KEY_PATH`.
   Use an App Store Connect **team API key** with the permissions needed for your
   app and signing resources. `ASC_KEY_PATH` points to the downloaded `.p8` file;
   keep it outside the repository when possible.
3. Set `APP_VERSION` and a `BUILD_NUMBER` higher than the previous upload for that
   version. The script preserves this build number rather than letting Xcode change it.
4. Run the commands below as needed.

```bash
./scripts/publish.sh check   # Check local settings without contacting Apple
./scripts/publish.sh export  # Build a signed archive and export an IPA
./scripts/publish.sh upload  # Build a fresh signed archive and upload to Apple
```

With no argument, the script runs `check`. Configuration checks do not verify
Apple credentials, signing permissions, or whether a build number is available.
Export and upload both require valid signing access and may contact Apple.
Each run saves its archive and export output under `build/app-store/`.

`.env` is local and ignored by Git; `.env.example` contains only blank settings
and is safe to share. Private keys and provisioning files are also ignored.
The script reads `.env` as shell configuration, so use only trusted contents.

An upload does **not** submit the app for review or release it publicly. After
Apple processes the build, complete the store listing, screenshots, privacy and
compliance information, select the build, and submit it for App Review in
[App Store Connect](https://appstoreconnect.apple.com/). See Apple's
[upload guide](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds)
for the build processing workflow.

## Persistence

`TaskList` and `TaskItem` are SwiftData models. `TaskList.tasks` uses a nullify relationship rule, so deleting a list preserves its tasks and returns them to Inbox.

The old 2020 Core Data store is intentionally not part of the modern runtime. If importing historical user data ever becomes necessary, implement it as a bounded one-time migration tool instead of restoring Core Data as a permanent dependency.

## Developer guide

See [Developer guide](docs/README-DEV.md) for architecture, Material 3 conventions, testing, persistence rules, and development commands.

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

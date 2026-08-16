# HarmonyOS App Market Dashboard

HarmonyOS front-end repository. The overall project is a multi-platform application ecosystem powered by a Rust back end, including HarmonyOS, iOS, Android and Web editions; this repository contains only the HarmonyOS front end.

The current application bundle name is `top.rayawa.dashboard`, the current version is `2.2.1`, and the main module uses the HarmonyOS Stage model.

[![HarmonyOS API](https://img.shields.io/badge/HarmonyOS-API%2023%2B-blue)](#)
[![Languages](https://img.shields.io/badge/Language-ArkTS%20%7C%20Rust-orange)](#)
[![Platform](https://img.shields.io/badge/Platform-Cross--Platform%20Backend-lightgrey)](#)

## Project Positioning

The HarmonyOS App Market Dashboard is used to aggregate and display HarmonyOS app market data, while also providing app query, app submission, links, sharing and user settings capabilities.

At present, this application takes on two responsibilities:

- As the dashboard browsing client, it carries multi-site content presentation and page interaction
- As the system capability entry point, it receives sharing, query, submission and cross-device sharing flows

## Overall Architecture

The whole project is driven by a unified back end, while multiple front ends consume the same core data capabilities.

### Back end

The back end is implemented with a Rust stack and is responsible for data aggregation, API exposure, database access and server-side orchestration.

- Language: Rust `Edition 2024`
- Web framework: Axum `0.8`
- Async runtime: Tokio `1.47`
- Database: PostgreSQL `12+`
- Database driver: SQLx `0.8`
- HTTP client: Reqwest `0.12`
- Serialisation: Serde + Serde JSON + TOML
- Logging: Tracing + Tracing Subscriber
- Compression: Tower HTTP, supporting Brotli, Gzip, Deflate and Zstd

### Front-end matrix

The project has the following front-end forms:

- HarmonyOS
- iOS
- Android
- Web

This repository corresponds to the HarmonyOS front end.

## What This Repository Covers

This repository implements the HarmonyOS client with ArkTS, ArkUI and ArkWeb, and is mainly responsible for:

- Multi-site dashboard browsing
- App query pages and query share entry points
- App submission pages and submission share entry points
- User pages, about pages and log pages
- Local settings, user profile data and local cache
- System sharing, knock-to-share and air gesture sharing
- HarmonyOS-native page flow and interaction adaptation

## Main Features

- `Dashboard` home page
  Provides switching between T site, Egui and S site, and handles WebView rendering, navigation bar, bottom bar, loading state, share synchronisation and floating action buttons.
- App query
  Supports in-app queries and also query flows triggered from external shared links.
- App submission
  Supports both simple and complex submission flows, both of which can be triggered from system share entry points.
- User and settings
  Supports nickname settings, submission/query entries, contact information and preference settings.
- Links
  Centrally manages related websites and app market entry points.
- About and agreements
  Displays API documentation, update logs, user agreement and privacy policy content.
- Distributed sharing
  Supports the system share sheet, passive sharing, knock-to-share and air gesture sharing.

## Technology Stack

- Language: ArkTS
- UI: ArkUI
- Web container: ArkWeb
- Project model: HarmonyOS Stage Model
- Build tool: Hvigor
- Testing: Hypium / Hamock

## Runtime Environment

- DevEco Studio `6.1.0+`
- HarmonyOS SDK
  Recommended according to the project configuration:
  - `targetSdkVersion: 6.1.0(23)`
  - `compatibleSdkVersion: 6.1.0(23)`
- Device types: phone / tablet / 2in1
- HarmonyOS device or emulator

## Project Structure

```text
.
├── AppScope/                         Application-level configuration and global resources
│   ├── app.json5                     Application metadata: bundle name, version, icon, label, etc.
│   └── resources/                    AppScope-level resources
│       ├── base/                     Shared resources under the default theme
│       │   ├── element/              Global strings and similar resources
│       │   └── media/                App icons, buttons, illustrations and other media
│       ├── dark/                     Media overridden for dark mode
│       │   └── media/                Dark theme image resources
│       └── phone-*/media/            App icon resources for different screen densities
├── entry/                            HarmonyOS main business module
│   ├── src/main/                     Main source directory for the module
│   │   ├── ets/                      ArkTS source directory
│   │   │   ├── ability/              UIAbility / ShareExtensionAbility entry points
│   │   │   ├── abilityPages/         Standalone pages launched by abilities
│   │   │   ├── common/               Constants, API, types, storage, sharing and utilities
│   │   │   ├── component/            Reusable UI components
│   │   │   ├── pages/                Main pages and sub-pages
│   │   │   └── utils/                Logging utilities and similar helpers
│   │   └── resources/                Module-level resources
│   │       ├── base/                 Default resources
│   │       │   ├── element/          Module strings, colours, dimensions and similar resources
│   │       │   ├── media/            Images and icons used by the module
│   │       │   └── profile/          Routing tables, page registration, backup config and similar profile resources
│   │       ├── dark/                 Dark mode resources
│   │       │   └── element/          Dark theme colour overrides
│   │       └── rawfile/              Raw file resources
│   │           ├── arkdata/utd/      UTD configuration and similar data files
│   │           └── knock_share_guide/Raw assets such as knock-to-share guide images
├── build-profile.json5               Build and signing configuration
├── hvigorfile.ts                     Hvigor build entry
└── oh-package.json5                  Dependency declaration
```

## `entry/src/main/ets` in Detail

This is the core implementation directory of the project and can be understood through the `ability`, `abilityPages`, `pages`, `component`, `common` and `utils` groupings.

### `ability/`

This layer is responsible for system entry points, share entry points and standalone ability lifecycle management.

- `ability/entry.ets`
  Main `UIAbility` entry. It loads `pages/Dashboard`, handles continuation data restoration, and uses `AppStorage` to participate in cross-device continuation with the current browsing state.
- `ability/submitEntry.ets`
  `UIAbility` for the submission flow. It receives parameters from sharing, stores them in `AppStorage`, and then loads `abilityPages/complexSubmit`.
- `ability/queryEntry.ets`
  `UIAbility` for the query flow. It receives the target query link, writes it into `AppStorage`, and then loads `abilityPages/queryWeb`.
- `ability/query.ets`
  Query share extension ability. It parses the package name from system share content, calls the back-end API to obtain the app ID, builds the final query page link and then launches `queryEntryAbility`.
- `ability/simpleSubmit.ets`
  Simple submission share extension ability. It does not show a complex form; instead, it directly parses the package name or app ID from shared content and submits it through the back-end API.
- `ability/complexSubmit.ets`
  Complex submission share extension ability. It receives shared content and forwards the user to the form page so they can complete and submit extra information.

### `abilityPages/`

This layer contains standalone pages launched directly by abilities, usually for strongly structured flows such as sharing and querying.

- `abilityPages/loading.ets`
  Minimal loading page used by share extension abilities to show the user that the app is establishing communication with the database.
- `abilityPages/queryWeb.ets`
  Web page dedicated to query abilities. It reads the query URL passed in from the ability, renders the results with ArkWeb, and reuses floating buttons, hand-hold detection and progress bar interactions.
- `abilityPages/complexSubmit.ets`
  Complex submission form page. It receives shared content, automatically extracts app information, fills the form, arranges submission buttons and handles exit behaviour. It is the core page of the submission flow.
- `abilityPages/continueWeb.ets`
  Continuation web page. Used for cross-device continuation scenarios with web content display.

### `pages/`

This layer contains regular in-app navigation pages.

- `pages/Dashboard.ets`
  The application home page and the main dashboard page. It manages multi-site configuration, multiple `WebviewController` instances, loading progress, bottom tabs, floating buttons, share synchronisation, continuation state and split-layout adaptation. It is the core page of the client.
- `pages/friend.ets`
  Links page. It gathers community websites, third-party stores and related app entries, and handles either opening external sites or jumping to app market detail pages.
- `pages/friendWeb.ets`
  Links detail page. It opens external sites in a WebView and warns the user that the content does not belong to the dashboard itself, while still retaining sharing, scrolling and floating-button capabilities.
- `pages/queryWeb.ets`
  Regular in-app query page. It is similar to the ability-based query page, but serves internal app navigation and is responsible for displaying query results for a given URL.
- `pages/tutorial.ets`
  First-run guidance page. Introduces new users to the app's core features and usage.
- `pages/user.ets`
  User centre page. It manages username settings, submission entry points, query entry points, contact information and settings overlays. It is the aggregation page for user actions and preferences.

### `pages/user/`

This layer contains child pages under the user centre.

- `pages/user/about.ets`
  About page. It displays the app icon and version information, and provides entry points to API documentation, web update logs, app update logs, the user agreement and the privacy policy.
- `pages/user/aboutWeb.ets`
  Web content page under the About section. It is used to open API documentation or web update logs, while preserving sharing, loading progress and floating interactions.
- `pages/user/appLog.ets`
  App update log page. It contains built-in version change records and supports filtering by `beta`, `rc` and `release`.
- `pages/user/htmlPage.ets`
  Local HTML display page. It is mainly used to show local agreement pages such as `approve.html` and `privacy.html`, and also supports revoking agreement consent, clearing local state and exiting the app.

### `component/`

This layer contains reusable components rather than standalone routed pages, but many pages depend on these components to compose their interfaces.

- `component/settings.ets`
  Settings panel component, centralising preference management.
- `component/appQuery.ets`
  Query input component.
- `component/appSubmit.ets`
  Submission input component.
- `component/contact.ets`
  Contact information display component.
- `component/submitButtons.ets`
  Submission flow button group.
- `component/queryButtons.ets`
  Query flow button group.
- `component/confirmButtons.ets`
  Confirmation action button group.
- `component/warn.ets`
  Important notice or agreement warning component.
- `component/KnockShareGuideCard.ets`
  Knock-to-share guidance card.

### `common/`

This layer provides cross-page business logic and foundational capabilities.

- `common/constants.ets`
  Site addresses, app version, custom UA and other constants.
- `common/types.ets`
  Type definitions.
- `common/url.ets`
  URL construction utilities.
- `common/utils.ets`
  Text parsing and general utility logic.
- `common/NaturalLanguageExtract.ets`
  Information extraction capability for the submission flow, used to identify app information from natural language input.
- `common/DiskStorage.ets`
  Local persistence wrapper.
- `common/SettingsStorage.ets`
  Settings storage wrapper.
- `common/profile.ets`
  Storage wrapper for usernames and related profile data.
- `common/shareControl.ets`
  Share controller, unifying system sharing and passive sharing.
- `common/vibration.ets`
  Haptic feedback wrapper.
- `common/got.ets`
  Reserved / experimental network wrapper implementation.

### `utils/`

- `utils/Logger.ets`
  Logging wrapper used by sharing and common logic.

## Core Sites and Configuration

The main site constants defined in the current code are in `entry/src/main/ets/common/constants.ets`:

- `https://hmos.txit.top/`
- `https://shenjack.top:10003/`
- `https://shenjack.top:10003/egui/`

If you need to switch environments or replace sites, update this file first.

## Permissions

The current module declares the following permissions:

- `ohos.permission.INTERNET`
- `ohos.permission.DETECT_GESTURE`
- `ohos.permission.VIBRATE`
- `ohos.permission.DISTRIBUTED_DATASYNC`

Permission configuration is located in `entry/src/main/module.json5`.

## Testing

The repository already contains the basic test directories:

- `entry/src/test/`
- `entry/src/ohosTest/`

This README does not expand test command instructions because the project is mainly run and debugged through the DevEco Studio workflow.

## Known Notes

- This repository contains only the HarmonyOS front end and does not include the Rust back-end source code.
- `README_en.md` and `README_fr.md` are now aligned with the current Chinese README structure.
- The repository does not currently declare an explicit open-source licence. If you intend to publish it publicly, add a `LICENSE` file and update the declaration in `entry/oh-package.json5`.

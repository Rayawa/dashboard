# Dashboard Application Viewer

[简体中文](README.md) · [English](README_en.md) · [Français](README_fr.md)

Dashboard Application Viewer is the native client for `harmony_get_market`. It queries public SDK, version, category, and rating information through the back end's `/api/v0` endpoints while retaining the ArkWeb entry to the S Site.

- Bundle name: `top.rayawa.dashboard`
- Version: `3.1.0`
- Build number: `30100001`
- Target and compatible version: system `6.1.0(23)` (API 23)
- Devices: phone, tablet, and 2in1
- Branch: `v3.0.0(23)`, migrated from `shenjack`

## Version 3.0.0 interface

The root page uses `HdsNavigation`, child pages use `HdsNavDestination`, and four main pages are connected by fixed-title `HdsTabs`. The bottom bar no longer auto-hides or uses a manually specified size:

1. **S Site** — warms up and caches its ArkWeb page at app startup and supports sharing the current page, Knock-to-Share, and air-gesture sharing. An independent Web viewport keeps floating detail dialogs in the current view.
2. **Home** — shows that the total equals applications plus Atomic Services; wide layouts place totals, service status, and recently listed apps side by side.
3. **App Details** — places search and an overview/list switcher at the top. The list supports type and field filters, sorting, and pagination.
4. **My** — shows the app icon and names, settings, additional links, version, copyright, and ICP filing information. The tutorial is intentionally available here only, rather than duplicated in the title bar; Contact Us opens as a dismissible half-modal sheet.

The app list, search results, deep links, and system-share entry all use the same native detail template:

```text
Locate app → load API data with a loading state → inject data → render the native detail template
```

The detail page contains an app summary, compact tag-and-text metadata, screenshots, download and rating trends, description, and release notes. Charts support point selection, pinch-to-zoom, and one-finger panning. Sharing from this page creates an S Site detail card with the app icon.

Cross-device continuation saves the selected main tab, App Details subview, native detail target, and scroll position. The target device restores `pages/Dashboard` before navigating back to the corresponding tab or detail location. Only version 3.0.0 or later accepts the current continuation format.

Home and App Details support pull-to-refresh from the top. The S Site title bar reads the current ArkWeb URL at share time, so system sharing, Knock-to-Share, and air-gesture sharing always send the current page. While an in-page detail dialog is open, the system Back action or back-swipe closes that dialog first. Re-tapping the selected S Site tab returns to the S Site home page.

## Data, cache, and weak-network behavior

All native data pages use `common/MarketApi.ets`; pages do not construct HTTP requests directly. Every API request includes the same app User-Agent.

- Home data is fresh for 5 minutes, list data for 2 minutes, and detail/chart data for 30 minutes.
- A valid cache entry is read directly from local storage to reduce startup and navigation delays.
- After expiry, the app requests the network; on failure, it can fall back to cached data up to 30 days old.
- Pages clearly mark offline cache data and display its timestamp.
- Submission requests are never cached, and background updates for existing apps bypass fresh cache entries.
- Clear Cache removes API cache files, ArkWeb storage, and cookies while retaining the username and settings.
- The current API cache size is displayed beside Clear Cache under My → Settings.

## Error handling and logging

- File, window, network, prompt, share-session, and optional-device-capability calls provide exception or rejection fallbacks.
- Toast messages are routed through `common/safeUi.ets`; a temporarily unavailable UI context is logged without interrupting the main flow.
- Console messages use the `[Dashboard][module path][level]` prefix for easier filtering.
- Smart Holding checks `SystemCapability.MultimodalAwareness.Motion` before use and restores the standard button layout on unsupported devices.
- The default system-share thumbnail and vibration-effect capability results are reused after first use, avoiding repeated resource reads and capability queries within a session.

## Settings and device capabilities

My → Settings persists the username, vibration intensity, light-field effect, and immersive material level. At startup, values are hydrated from Preferences into `AppStorage`; later reads use the in-process cache while writes remain persistent.

- The username is included with submission requests; when left blank, the device name is used.
- Vibration offers Off, Dynamic, and Strong levels. The control is hidden on devices without vibration hardware.
- Light-field effects offer Dim, Bright, and High-Brightness levels. The last option requires API 24 HDR compositing; API 23 or devices without global HDR safely fall back to Bright.
- The app declares network, network-status, HDR-brightness, gesture-detection, and vibration permissions. Optional capabilities have fallback behavior when unavailable.

## Responsive layout and accessibility

Pages use shared window-width breakpoints:

- Small: `< 600vp`
- Medium: `600vp–839vp`
- Large: `≥ 840vp`

Cards, charts, and detail fields adjust their columns with `GridRow/GridCol`; the app list remains horizontally scrollable on narrow screens. Interactive controls, charts, images, states, and primary content provide Chinese `accessibilityText` labels.

Theme colors are maintained in:

- `entry/src/main/resources/base/element/color.json`
- `entry/src/main/resources/dark/element/color.json`

All `v3_*` colors provide light and dark variants. The S Site ArkWeb placeholder uses `#EEF6FE` in light mode and `#030712` in dark mode.

## Key directories

```text
entry/src/main/ets/
├── ability/                  EntryAbility, share-session loading page, and the single shareAbility
├── common/
│   ├── MarketApi.ets         shared API client
│   ├── CacheService.ets      file cache, size reporting, and full cleanup
│   ├── appState.ets          transient cross-Ability state
│   ├── storage.ets           Preferences and AppStorage hydration
│   ├── safeUi.ets            safe PromptAction calls and logging fallback
│   ├── safeNavigation.ets    route parameters and safe push/pop helpers
│   ├── motion.ets            page-entry and shared-transition animation
│   ├── shareControl.ets      system and inbound-share lifecycle
│   ├── vibration.ets         shared short, back, long, and error vibration
│   ├── visualEffects.ets     light-field and HDR compatibility fallback
│   ├── dashboardConfig.ets   server-controlled dashboard visibility
│   ├── constants.ets         shared constants
│   └── types.ets             API, page, and route types
├── component/
│   ├── charts/               native Home chart components
│   ├── SettingsPanel.ets     settings and cache management
│   ├── WarningContent.ets    first-launch notice content
│   └── ContactPanel.ets      contact and copy actions
└── pages/
    ├── Dashboard.ets         HdsNavigation and four fixed HdsTabs
    ├── main/
    │   ├── SStationPage.ets
    │   ├── HomePage.ets
    │   ├── SearchPage.ets
    │   ├── AppsPage.ets      combined app overview/list page
    │   └── MyPage.ets
    ├── detail/               shared native app-detail page
    ├── more/                 tutorial, links, update log, agreements, and developer pages
    └── web/WebPage.ets       shared remote-web destination
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for module boundaries, state rules, lifecycle, and resource ownership.

## Main API endpoints

- `GET /api/v0/market_info`
- `GET /api/v0/apps/list/{page}`
- `GET /api/v0/apps/app_id/{app_id}`
- `GET /api/v0/apps/pkg_name/{pkg_name}`
- `GET /api/v0/apps/metrics/{pkg_name}`
- `GET /api/v0/rankings/rate_history?pkg_name={pkg_name}`
- `GET /api/v0/charts/rating`
- `GET /api/v0/charts/min_sdk`
- `GET /api/v0/charts/target_sdk`
- `GET /api/v0/charts/api_history`
- `POST /api/v0/submit`

The back end's runtime routes are authoritative. See `API.md`, `API_DOCS.md`, and `/openapi.json` in the `harmony_get_market` repository for the complete reference.

## Development and verification

1. Open the project with DevEco Studio 6.1 or newer.
2. Install the required API 23 and system SDKs.
3. Configure a valid local signing profile; absolute paths from another developer's machine cannot be reused directly.
4. Build and test phone, tablet, or 2in1 targets on a device or emulator.
5. Verify weak-network fallback, cache clearing, light/dark themes, 600/840vp breakpoints, the single inbound share entry, all three sharing modes on the S Site and detail page, continuation position, table scrolling/page jumps, and screen-reader output.
6. On devices with and without HDR and vibration hardware, verify settings visibility, fallback behavior, and the High-Brightness warning.

## Privacy and notices

Market data is collected from the internet and is provided for reference only; its accuracy, completeness, and authenticity are not guaranteed. The app uses device information to construct its request User-Agent and anonymous runtime telemetry. A username explicitly set by the user is sent with submission requests. Refer to the in-app privacy policy for details.

Copyright © 2026 Ray Chen (Rayawa). All rights reserved. Filing domain: `rayawa.top`; ICP filing: 京ICP备2025153453号.

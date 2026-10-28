# Dashboard Application Dashboard

English | [简体中文](docs/i18n/README_zh.md)


[Simplified Chinese](README.md) · [English](docs/i18n/README.en.md) · [Français](docs/i18n/README.fr.md)

Dashboard is a native client for `harmony_get_market`. It queries public application information—SDK, version, category, rating and other fields—through the backend's `/api/v0` interfaces, while retaining an ArkWeb entry for S Site.

- Package: `top.rayawa.dashboard`
- Version: `3.2.0`
- Build: `30200001`
- Target: `26.0.0` (HarmonyOS 7 / API 26); minimum compatibility: `6.0.0(20)` (API 20)
- Devices: phone, tablet, 2in1
- Current development branch: `v3.0.0(20)`

## 3.0.0 Interface Structure

Main pages use `HdsNavigation`; subpages use `HdsNavDestination`. Five primary pages are linked through fixed-title `HdsTabs`, with a system floating-material bottom bar:

1. **S Site**: ArkWeb warms and caches after the main UI appears during idle time. It supports sharing the current page, tap-to-share and air transfer. An independent web viewport keeps the site's floating details within the visible area.
2. **Home**: explicitly shows total applications = apps + atomic services. Wide layouts put information, status and recently indexed items side by side.
3. **Collections**: between Home and Details, with app/developer segments. A title-bar management page supports selection across categories and batch removal.
4. **Details**: a fixed Overview/Table selector in the title bar. Search opens through shared-element animation; the table supports type/field filters, sorting and pagination.
5. **My**: AppIcon, Chinese/English names, settings, additional features and version/copyright/registration information. The tutorial entry exists only here instead of duplicating a title-bar action. Contact uses a half-modal page dismissible by tapping the overlay.

Application lists, search results and system-share entry points use one shared detail template:

```text
Find app → API loading (with loading state) → Inject data → Native detail template
```

Details include an application summary, compact icon/text information, screenshots, rating trends, description and release changes. Trends fill their container and support touch selection, pinch zoom and one-finger panning. Sharing generates an S Site card with the application icon.

Cross-device continuation saves the selected main tab, detail subview, native detail target and scroll position. The destination restores `pages/Dashboard`, then navigates to the corresponding tab/detail position. Only versions 3.0.0+ support continuation to avoid incompatible state formats.

Home and Details support pull-to-refresh. The Details search button remains fixed in the title bar and uses the same advanced materials as other navigation pages. S Site reads the current ArkWeb address for system sharing, tap-to-share and air transfer. When an in-page detail overlay is open, system back/swipe dismisses it first. Selecting the S Site tab again returns to its home page.

## 3.2.0

Adds reputation-ranking summaries and full rankings, report windows, minimum net-sample thresholds and two score-ordering modes. Details load in blocks, screenshots use windowing, line charts render linearly and work is frame-scheduled. Search is paginated; tables use lazy loading and stable rows. Startup, background work, continuation and cache waiting are optimized. Full user-facing changes are in `entry/src/main/ets/config/updateLogs.ets`.

Desktop regressions: `node scripts/test-performance.cjs` and `node scripts/test-discovery-feedback.cjs`. HAP build: `bash scripts/build.sh debug`. Desktop algorithm checks do not replace physical-device FPS/GPU analysis.

## Data, Cache and Weak-Network Strategy

Native business pages share `services/api/MarketApi.ets` rather than assembling HTTP requests in each page. All API requests carry one application User-Agent.

- Cache durations: Home 5 minutes, lists 2 minutes, details/charts 30 minutes.
- Read the capacity-bounded process cache first, then local files. Successful network results do not wait for file-cache persistence.
- Details and historical metrics may show cached data up to 30 days old while a background refresh is merged. Other endpoints request after expiry and fall back to available stale data on failure.
- The UI explicitly marks offline cache and its timestamp so stale results are not mistaken for live data.
- Submission requests are not cached; backend updates to existing applications bypass fresh cache.
- Only successful business responses containing objects/arrays are cached. Failures do not overwrite successes, and historical failed caches are not used for fallback.
- Identical requests share in-flight work. Forced refreshes and normal reads are separated so refresh does not reuse an old request.
- File I/O, capacity counting and cleanup are asynchronous. API-cache maintenance is deferred; metadata removes expired and leftover temporary files, then oldest saved entries are evicted under a 32 MiB budget. ArkWeb storage is separate.
- Cache writes use temporary files and replacement. Clearing cache invalidates earlier pending writes so late requests cannot restore cleared data.
- Clear Cache removes API files, ArkWeb storage and cookies while preserving username and settings.
- My → Settings → Clear Cache shows the total file size and reuses the calculation for 15 seconds.

Since 3.1.1, download counts, application counts, byte sizes and trend counters display raw values. Home's daily top-download ranking deduplicates applications, retaining the latest dated entry.

Since 3.2.0, chart axes use compact units, dates wrap across lines and legends wrap to available width. Download details and application fields retain exact values. Percentages use at most two decimals; nonzero tiny shares show “less than 0.01%”.

## Error Handling and Logs

- File, window, network, PromptAction, sharing-session and optional-capability calls use `try/catch` or Promise-rejection fallbacks.
- Toasts use `ui/feedback/safeUi.ets`. If UIContext is temporarily unavailable, the error is logged without breaking the main flow.
- `console` logs consistently use `[Dashboard][模块路径][级别]` prefixes for module/severity filtering.
- Grip awareness first checks `SystemCapability.MultimodalAwareness.Motion`; unsupported devices reset its local state and retain the ordinary button layout.
- Default share thumbnails and haptic capabilities are reused after the first check to avoid repeated resource/capability queries within a session.

## Settings and Device Capabilities

My → Settings saves username, vibration strength, lighting effects and immersive-material level. Startup hydrates Preferences into `AppStorage`, and subsequent reads use the process cache. Each change remains persisted locally.

- Submissions include the username; if blank, the device name is used.
- Haptics offer Off, Dynamic and Firm levels; the setting is hidden without vibration hardware.
- Lighting offers Dim, Bright and Highlight. Highlight requires API 24 HDR composition; API 23 or devices without global HDR safely fall back to Bright.
- The manifest declares network, network-status, HDR brightness, gesture-detection and vibration permissions. Optional capabilities have unavailable-device fallbacks.

## Responsive Layout and Accessibility

Shared width breakpoints:

- Small: `< 600vp`
- Medium: `600vp–839vp`
- Large: `≥ 840vp`

Statistics, charts and detail fields adjust columns through `GridRow/GridCol`. Application tables scroll horizontally on narrow screens. Interactive controls, charts, images, status hints and major content provide Chinese `accessibilityText`.

Colors are maintained centrally in:

- `entry/src/main/resources/base/element/color.json`
- `entry/src/main/resources/dark/element/color.json`

All added `v3_*` colors have light/dark variants. S Site's ArkWeb placeholder background is `#EEF6FE` in light mode and `#030712` in dark mode.

## Haptics, Important Notice and Half-Modal Interaction

Interactive controls use `utils/device/vibration.ets` and honor My → Settings levels: Off, Dynamic and Firm. Ordinary buttons, filters, chart selection, pagination and web actions use short pulses. Title-bar, system-back and swipe-back actions use deduplicated back feedback.

- First launch shows a non-bypassable important notice after the main container is ready. The user must agree or choose Cancel and Exit. Before agreement, attempts to dismiss through system back, swipe, drag or overlay retain the notice and provide a long vibration with a prompt to read and agree.
- Reopening the notice from My allows normal dismissal through Close, system back, swipe or overlay, with a short vibration.
- Contact uses `bindSheet` with `enableOutsideInteractive: false`. Under the default tablet follow-hand presentation, the overlay intercepts underlying-page interaction; tapping outside first closes the sheet.
- Cache-clear and privacy-consent-withdrawal confirmations, including cancellation, also provide haptic feedback.

## Key Directories

```text
entry/src/main/ets/
├── abilities/
├── pages/
│   ├── Dashboard.ets
│   ├── main/          SStationPage, HomePage, CollectionPage, AppsPage, MyPage
│   ├── collection/    CollectionManagementPage
│   ├── search/
│   ├── detail/
│   ├── discovery/
│   ├── settings/
│   ├── web/
│   └── startup/
├── components/        common, apps, charts, collection, detail, discovery, home, ...
├── models/
├── domain/            apps, charts, collection, discovery, rankings, sdk, search
├── services/          api, cache, sharing, storage, telemetry
├── state/
├── config/
├── ui/                animation, charts, feedback, icons, interaction, navigation, theme
└── utils/             device, diagnostics, format, links, runtime, url, web

docs/                  architecture, i18n
scripts/               build and verification tools
```

See [ARCHITECTURE.md](docs/architecture/overview.md) for complete module boundaries, state constraints, lifecycle and resource-release rules.

Debug builds use the `default` product and `debug` mode. Distribution builds use the `release` product, `release` mode and matching signing configuration. Signing material stays outside the repository and is referenced by local configuration.

Local quick builds: `./scripts/build.sh debug` produces a debug HAP; `./scripts/build.sh release` produces a signed release APP. The script selects the matching product and build mode.

## API Reference

Main client endpoints:

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

Backend runtime routes are authoritative. See `API.md`, `API_DOCS.md` and `/openapi.json` in `harmony_get_market` for complete documentation.

## Development and Verification

1. Open the project in DevEco Studio supporting HarmonyOS SDK 26.0.0.
2. Install HarmonyOS SDK 26.0.0 and retain API 20 minimum compatibility when building.
3. Check that signing paths refer to valid local files. Another developer's absolute paths cannot be used directly.
4. Build and validate on phone, tablet or 2in1 devices/emulators.
5. Focus on weak-network fallback, cache clearing, light/dark modes, 600/840vp breakpoints, the single share entry, three sharing modes for S Site/details, continuation positions, table scrolling/page jumps and accessibility announcements.

Before release, verify installation, startup, main tabs, web pages, sharing and continuation on target devices from API 20 through API 26.
6. Check haptic preferences, blocked initial-notice dismissal with long vibration, normal later dismissal and the tablet Contact sheet's overlay interception/outside-tap dismissal.
7. Check setting visibility, fallbacks and Highlight messages both with and without HDR/vibration hardware.

## Privacy and Notes

Market data is collected online and is not guaranteed accurate, complete or authentic; it is for reference. The app uses device information for its User-Agent and anonymous runtime telemetry. A user-specified username accompanies submissions. The in-app privacy policy defines handling details.

Copyright © 2026 project maintainer. All rights reserved. Registered domain: `rayawa.top`; ICP filing: 京ICP备2025153453号.

## Documentation

See [AGENTS.md](AGENTS.md) for repository conventions and [architecture](docs/architecture/overview.md) for module boundaries. Translations are linked above. Agent plans and execution reports are not stored in the repository.

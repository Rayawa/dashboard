# Dashboard App Dashboard for HarmonyOS

This repository contains the HarmonyOS native client for `harmony_get_market`. It consumes the Rust back end's `/api/v0` endpoints and retains the S-site ArkWeb entry.

- Bundle: `top.rayawa.dashboard`
- Version: `3.0.0`
- Build: `30000005`
- Target and compatible SDK: HarmonyOS `6.1.0(23)` (API 23)
- Devices: phone, tablet, and 2in1
- Development branch: `v3.0.0(23)`, created from `shenjack`

## Version 3 interface

The root uses `HdsNavigation`, child destinations use `HdsNavDestination`, and a fixed-title `HdsTabs` hosts five tabs. The bottom bar no longer auto-hides or receives a manual size:

1. Web S Site — existing ArkWeb behavior.
2. Home — welcome/status information, exact market totals, total apps, and newly listed apps.
3. Search — search, simple submission, query update, and the single system-share entry. All matching results are shown in horizontally scrollable 20-item columns; existing-app updates stay silent.
4. App Details — a fixed two-way segment switches between native market overview charts and the 20/50/100-row sortable, scrollable, paginated app list.
5. My — icon and names, settings, restored More links, and version/copyright/ICP details.

Every list, search, deep-link, and share flow uses one native detail template:

```text
Locate app → fetch API data with a loading state → inject data → render the detail template
```

The detail page uses compact tag-and-text metadata, screenshots, download and rating line charts with axes, horizontal browsing, zoom and point selection, plus description and release notes. Button sharing, knock-to-share, and air-gesture sharing are enabled on this page. Share data includes a title, description, AppIcon thumbnail, and `https://shenjack.top:10003/dashboard?app_id=...`.

Continuation saves the selected main tab, App Details subview, detail target, and scroll offset. The target device restores `pages/Dashboard` before returning to the corresponding native location. Only version 3.0.0 or later accepts continuation state.

Only main-page title bars other than Web S Site provide a Tutorial button; child pages do not duplicate it. Re-tapping the current bottom tab scrolls that page to the top; re-tapping Web S Site returns to its home URL. Version 3.0.0 shows the important notice once after upgrade.

## Network and cache behavior

- One `common/MarketApi.ets` client owns API calls and attaches the app User-Agent to every request.
- Home data is fresh for 5 minutes, list data for 2 minutes, and detail/chart data for 30 minutes.
- A failed network request may fall back to a cache entry up to 30 days old, with an explicit offline-cache notice.
- Submission requests are never cached; background update requests bypass a fresh cache.
- Clear Cache removes API files, ArkWeb storage, and cookies while retaining the username and settings.
- The current cache-file size is displayed beside Clear Cache.

## Source layout

```text
entry/src/main/ets/
├── ability/              EntryAbility and the single shareAbility
├── abilityPages/         share-session loading page
├── common/               API, cache, state, storage, constants, types, and utilities
├── component/
│   ├── charts/           native Home charts
│   └── settings.ets      settings and cache management
└── pages/
    ├── Dashboard.ets     HdsNavigation and five fixed HdsTabs
    ├── main/             the five main tabs
    ├── detail/           shared native app-detail destination
    └── more/             tutorial, links, web documents, log, and agreements
```

Colors are defined in both `entry/src/main/resources/base/element/color.json` and `entry/src/main/resources/dark/element/color.json`. Responsive layout uses `<600vp`, `600–839vp`, and `≥840vp` breakpoints. Interactive and primary content exposes Chinese accessibility labels.

## Build and verification

Open the project with DevEco Studio 6.1 or newer and install the API 23 HarmonyOS and HMS SDKs. Configure a valid local signing profile, then verify phone, tablet, and 2in1 targets. Pay particular attention to weak-network fallback, complete cache clearing, light/dark themes, breakpoint transitions, the single share entry, all three detail-sharing modes, continuation position, table scrolling/page jump, and screen-reader output.

Copyright © 2026 Ray Chen (Rayawa). All rights reserved. ICP filing: 京ICP备2025153453号.

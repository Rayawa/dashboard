# dashboard

English | [简体中文](docs/i18n/README_zh.md)

A native HarmonyOS client for browsing application-market data, trends and saved collections.

## Overview

Dashboard presents market summaries, application/developer search, filtered tables, details, trend charts and collections. Native pages share an API/cache layer; an ArkWeb tab provides access to the related web service. The backend is an external dependency and is not implemented in this repository.

## Technology and Dependencies

ArkTS, ArkUI/HDS, OHPM and Hvigor. The build template targets SDK 26.0.0 with API 20 compatibility. Runtime features use HarmonyOS platform APIs; tests use Hypium/Hamock. Access to the configured market API is required for live data.

## Repository Structure

- `entry/src/main/ets/` — ArkTS application code
- `entry/src/main/resources/` — resources and routes
- `AppScope/` — application metadata
- `build-profile.example.json5` — build configuration template
- `oh-package.json5` — package dependencies
- `entry/src/main/ets/domain/` — business rules
- `entry/src/main/ets/services/` — API, cache and device integrations
- `entry/src/main/ets/pages/` — main tabs and business screens
- `docs/` — architecture, development and translations
- `scripts/` — build and regression checks

## Quick Start

1. Open the repository root in DevEco Studio with the SDK required by `build-profile.example.json5`.
2. Copy that template to `build-profile.json5`, restore OHPM dependencies and configure signing locally if installing on a device.
3. Select the `entry` module and a compatible device/emulator, then build and run from the IDE. Keep certificates and machine-specific paths outside version control.

Check the service endpoint configuration before loading market data. For a terminal debug build, run `bash scripts/build.sh debug`. The architecture is described in [docs/architecture/overview.md](docs/architecture/overview.md).

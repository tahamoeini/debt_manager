<!-- Copilot instructions for AI coding agents working on Debt Manager -->
# Debt Manager — Quick AI Agent Guide

Be concise. Make minimal, focused edits; prefer small PRs for schema or contract changes.

- Project type: Flutter app (mobile + web + desktop) rooted at [debt_manager](debt_manager).
- Entry points: `lib/main.dart`, `lib/app.dart`, `lib/app_shell.dart`.

**Big picture**
- Major layers: `lib/core/` (shared services, DB, compute), `lib/features/` (domain feature modules), `lib/components/` (design system + reusable widgets).
- Data flows: UI → Riverpod providers (`lib/core/providers/core_providers.dart` / `lib/features/*/providers`) → services (`lib/core/*`) → `DatabaseHelper.instance` (`lib/core/db/database_helper.dart`) or compute isolates (`lib/core/compute/*`).

**Key conventions (do not break)**
- Singletons: many services use `.instance`. Reuse them (e.g., `DatabaseHelper.instance`).
- Isolates: heavy computations live in `lib/core/compute/`. Expose top-level functions that accept and return plain Maps/Lists (no closures, no complex objects).
- Dates & currency: use `lib/core/utils/jalali_utils.dart` for Jalali conversions; persist dates as `yyyy-MM` / `yyyy-MM-dd`. Currency stored in smallest units (see `AddBudgetEntryScreen`).
- Localization: strings live in `l10n/` (`intl_en.arb`, `intl_fa.arb`); app is Persian/RTL—preserve direction and string semantics.

**Where to implement changes**
- DB/schema: `lib/core/db/` and `lib/core/models/`.
- Compute/analytics: `lib/core/compute/` and `lib/core/smart_insights/`.
- Notifications: `lib/core/notifications/` and `lib/core/smart_insights/`.
- UI/components: `lib/components/`, `lib/features/*/screens`.

**Developer workflows / commands**
- Install deps: `flutter pub get`.
- Format: `dart format --output=none --set-exit-if-changed .`.
- Static analysis: `flutter analyze`.
- Tests: `flutter test` (CI uses concurrency flags).
- Run app: `flutter run -d <device>` (android/ios/web/windows/linux/macos). For Windows desktop ensure Visual Studio/CMake toolchain is set.

**Integration points & notable deps**
- `shamsi_date` — Jalali helpers in `lib/core/utils/jalali_utils.dart`.
- `flutter_local_notifications` — scheduling and channels under `lib/core/notifications/`.
- DB access centralized in `DatabaseHelper.instance` (`lib/core/db/database_helper.dart`).

**Small examples**
- Compute entry template: add a top-level function in `lib/core/compute/your_compute.dart` that accepts `Map` and returns `Map`/`List` (serializable). Call with `compute(yourEntry, argsMap)`.
- DB read example: use `DatabaseHelper.instance.getAllLoans()` (map models with `.toMap()` / `.fromMap()` in `lib/core/models`).

Run checks before PRs: `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`.

If you want small code snippets (compute entry, DB helper usage, Riverpod provider example), tell me which and I'll add them.
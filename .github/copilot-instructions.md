<!-- Copilot instructions for AI coding agents working on Debt Manager -->
# Debt Manager — Copilot / AI agent instructions

Be concise and make minimal, focused edits. This file documents project-specific patterns, conventions and entry points that help an AI agent be productive immediately.

- Project type: Flutter app (mobile + web + desktop) in `debt_manager/`.
- Major areas: `lib/core/` (shared services, DB, compute), `lib/features/` (feature modules), `lib/components/` (UI/design components).

- Key singletons & services
  - `DatabaseHelper.instance` (`lib/core/db/database_helper.dart`) — central SQLite access. Use its methods (e.g., `getAllLoans()`, `getInstallmentsByLoanId()`) rather than raw DB file paths.
  - Notification services: `lib/core/notifications/*` and `NotificationService` wrappers. Android/iOS channel setup appears in `smart_notification_service.dart`.
  - Smart insights engine split:
    - Heavy compute functions live under `lib/core/compute/*.dart` and must accept/return plain Maps (safe for `compute()` isolates).
    - Lightweight orchestrator and UI-facing service live under `lib/core/insights/` and `lib/core/smart_insights/` — call these when scheduling notifications or building widgets.

- Data/format conventions
  - Dates: app uses Jalali dates via `shamsi_date` and helpers in `lib/core/utils/jalali_utils.dart`. Persist date strings in `yyyy-MM` or `yyyy-MM-dd` format.
  - Currency: amounts are stored in the smallest unit (see `AddBudgetEntryScreen`: input value multiplied by 100). Respect this when reading/writing amounts.
  - Compute/Isolate contract: pass plain Maps/Lists to compute entry functions (e.g., `computeDetectSubscriptions`, `spendingByCategoryEntry`). Do not pass complex objects or closures.

- Patterns & conventions
  - Many services expose a `.instance` singleton factory. Prefer reusing singletons rather than creating new instances unless explicitly needed.
  - Providers: Riverpod providers live under `lib/core/providers/core_providers.dart` and feature providers in `lib/features/*`. Use `ref.read(...)`/`ref.watch(...)` in widgets.
  - UI strings: app is Persian/RTL; preserve existing text and directionality when editing UI. Keep localized strings inline for small fixes, but avoid globalizing unless asked.
  - Async/UI safety: codebase prefers checking `if (!mounted) return;` before using `context` after awaits; follow this pattern when adding async work that touches UI.

- Build / test / dev commands
  - Static analysis: `flutter analyze` (used during CI and locally).
  - Run unit/widget tests: `flutter test`.
  - Run app: `flutter run -d <device>` (project supports multiple platforms: android/ios/web/windows/linux/macos).

- Integrations & deps to be mindful of
  - `shamsi_date` for Jalali calendar operations.
  - `flutter_local_notifications` used for scheduling — modify channel IDs carefully.
  - Heavy compute tasks use Dart `compute()` isolates; keep compute entry points top-level and serializable.

- Where to make fixes or features
  - Data + compute changes: `lib/core/compute/` and `lib/core/db/`.
  - Background work / scheduling: `lib/core/notifications/` and `lib/core/smart_insights/`.
  - UX and components: `lib/components/`, `lib/core/widgets/`, `lib/features/*/screens`.

- Small code style hints found in repo
  - Avoid leading underscores for local variables in functions (analyzer rule used in the repo).
  - Prefer simple interpolation (`$var`) vs `${var}` patterns; follow existing interpolation style.
  - When adding compute entry functions, make sure all inputs are primitive/Map/List and outputs are plain Maps/Lists so isolates work.

Examples (common edits):
- Add a compute entry: put a top-level function in `lib/core/compute/your_compute.dart` that accepts Map and returns List/Map.
- Use `dateTimeToJalali()` from `lib/core/utils/jalali_utils.dart` when generating `yyyy-MM` prefixes.
- Use `DatabaseHelper.instance` for DB reads/writes; map model objects via `.toMap()` before passing to isolates.

If you need to change architecture-level pieces (DB schema, major service contracts), open a short PR and describe the migration steps (schema migration, cache invalidation). For small fixes, create focused commits and run `flutter analyze` and `flutter test` locally.

If anything above is unclear or you want more examples (e.g., compute function template, DB helper usage), tell me which area and I'll add a brief snippet.

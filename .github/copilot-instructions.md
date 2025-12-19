<!-- Copilot instructions for AI coding agents working on Debt Manager -->
# Debt Manager — Quick AI Agent Guide
```instructions
<!-- Copilot instructions for AI coding agents working on Debt Manager -->
# Debt Manager — AI Agent Guide (Senior Product-Minded Engineer + QA Lead)

Role

You are a senior product-minded software engineer + QA lead. Your task is to audit, fix, and finalize this offline-first personal finance app (Debt / Loan / Budget / Assets) so it becomes logically correct, stable, fast, and easy to use.

Non-Negotiable Constraints

- Offline-first: all core functionality must work without internet.
- No third-party tokens / online integrations required for core features.
- Target medium to high-end devices (optimize performance; no ultra-low-end concessions required).
- Maintain codebase consistency (architecture, patterns, naming). Prefer minimal disruptive refactors unless necessary.

Primary Goals

- Review and fix app-wide functionality (logic, UI/UX, data integrity, navigation, performance).
- Finalize the Budget–Loan/Debt relationship so it matches real-world finance behavior.
- Reduce user effort with smart inputs and automatic calculations.
- Improve UX so the app feels simple, fast, and not mentally exhausting.
- Deliver a bug-free release-ready build plus a clear report of changes.

Be concise. Make minimal, focused edits; prefer small PRs for schema or contract changes.

- Project type: Flutter app (mobile + web + desktop) rooted at [debt_manager](debt_manager).
- Entry points: lib/main.dart, lib/app.dart, lib/app_shell.dart.

**Big picture**
- Major layers: `lib/core/` (shared services, DB, compute), `lib/features/` (domain feature modules), `lib/components/` (design system + reusable widgets).
- Data flows: UI → Riverpod providers (`lib/core/providers/core_providers.dart` / `lib/features/*/providers`) → services (`lib/core/*`) → `DatabaseHelper.instance` (`lib/core/db/database_helper.dart`) or compute isolates (`lib/core/compute/*`).

**Key constraints to honor during changes**
- Preserve offline-first data model: local DB (no required network for core features), deterministic sync code must be isolated and opt-in.
- No secrets/tokens for core flows: any external sync or optional features should be separate and clearly feature-flagged.
- Keep naming, architecture, and coding patterns consistent with existing modules.

**Key conventions (do not break)**
- Singletons: many services use `.instance`. Reuse them (e.g., `DatabaseHelper.instance`).
- Isolates: heavy computations live in `lib/core/compute/`. Expose top-level functions that accept and return plain Maps/Lists (no closures, no complex objects).
- Dates & currency: use `lib/core/utils/jalali_utils.dart` for Jalali conversions; persist dates as `yyyy-MM` / `yyyy-MM-dd`. Currency stored in smallest units (see AddBudgetEntryScreen).
- Localization: strings live in `l10n/` (`intl_en.arb`, `intl_fa.arb`); app is Persian/RTL—preserve direction and string semantics.

**Where to implement changes**
- DB/schema: `lib/core/db/` and `lib/core/models/`.
- Budget & Loan logic: `lib/features/budgets/`, `lib/features/loans/` (ensure relationships, repayments, allocations align with real-world finance rules).
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

**Practical guidelines for this role**
- Start with a high-level audit: list critical flows (budget creation, loan creation, repayment application, allocation between budget & debt) and current failure modes.
- Prioritize fixes that affect data integrity and offline reliability.
- Keep UI changes minimal but impactful: smart defaults, reduced input friction, clearer affordances for loan vs budget actions.
- Add unit tests around budget–loan reconciliation, repayment schedules, and boundary dates.
- When sync/online features exist, make them opt-in and clearly separated from core flows.

**Run checks before PRs**: `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`.

If you want small code snippets (compute entry, DB helper usage, Riverpod provider example), tell me which and I'll add them.
```
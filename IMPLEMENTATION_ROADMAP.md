# Debt Manager Enhancement Roadmap

## Scope Overview
This document outlines the proposed enhancements across 7 major areas. **Total effort: ~2–4 weeks** depending on priorities and tflite inclusion.

---

## Phase 1: High-Value, Moderate Effort (Week 1–2)

### 1.1 Enhanced Auto-Categorization Dictionary
- **Current state**: `lib/features/automation/models/automation_rule.dart` has basic `BuiltInCategories.payeePatterns`.
- **Upgrade**:
  - Expand Persian/English merchant patterns in `lib/features/automation/built_in_categories.dart` (new file).
  - Include: utilities, food, transport, subscriptions, loans, etc.
  - Combine with user automation rules: compute score = (built-in match confidence + user rule priority).
  - Store rule frequency/success in `automation_rules_repository.dart` for adaptive ranking over time.
- **Effort**: ~4 hours. **Impact**: Immediate UX improvement in auto-categorization.
- **Files to create/modify**:
  - `lib/features/automation/built_in_categories.dart` (new, ~200 lines).
  - `lib/features/automation/models/automation_rule.dart` (add `successCount` field).
  - `lib/features/automation/automation_rules_repository.dart` (add `recordRuleSuccess()` method).

### 1.2 Cash-Flow Simulator & "Can I Afford This?" Feature
- **Current state**: `lib/features/reports/reports_repository.dart` has `projectDebtPayoff()` but no cash-flow projection.
- **Upgrade**:
  - Create `lib/core/compute/cash_flow_simulator.dart` with pure function: `simulateCashFlow(loans, installments, budgets, newRecurringCommitment, daysAhead) → List<DailyCashSnapshot>`.
  - Add screen `lib/features/home/screens/can_i_afford_this_screen.dart` (input: amount, frequency, duration).
  - Show result: "✓ Safe" / "⚠️ Tight" / "✗ Negative at day X".
  - Integrate with budgets and debt engine; highlight conflicts.
- **Effort**: ~6 hours. **Impact**: Core financial decision-making feature.
- **Files to create/modify**:
  - `lib/core/compute/cash_flow_simulator.dart` (new, ~150 lines).
  - `lib/core/models/cash_snapshot.dart` (new DTO, ~20 lines).
  - `lib/features/home/screens/can_i_afford_this_screen.dart` (new, ~250 lines).
  - `lib/features/home/home_screen.dart` (add button to launch simulator).

### 1.3 Achievements & XP System (Foundation)
- **Current state**: If `AchievementsRepository` exists, it's basic. Otherwise, create from scratch.
- **Upgrade**:
  - Add `lib/core/models/achievement.dart`: fields for `id`, `name`, `xpValue`, `category` (e.g., "payment", "budget", "early_payoff").
  - Add `lib/core/models/user_progress.dart`: `totalXP`, `streaks`, `lastAction`, `freedomDate`.
  - Extend `AchievementsRepository`:
    - `recordAction(ActionType)` — log payment, budget check, early payoff, etc.
    - `computeStreaks()` — days/weeks without missed payments or overspending.
    - `computeFreedomDate()` — use `projectDebtPayoff()` to estimate debt-free date.
    - `getAchievements()` — return list of unlocked milestones.
  - Hook into existing operations: when installment is marked paid, call `recordAction("payment_made")`.
- **Effort**: ~5 hours. **Impact**: Gamification foundation; user engagement.
- **Files to create/modify**:
  - `lib/core/models/achievement.dart` (new, ~30 lines).
  - `lib/core/models/user_progress.dart` (new, ~25 lines).
  - `lib/features/achievements/achievements_repository.dart` (new/extend, ~150 lines).
  - `lib/features/achievements/screens/progress_screen.dart` (new, ~300 lines).
  - Integration hooks in existing pay/budget screens (small, ~2–3 lines each).

---

## Phase 2: Medium Effort, High Impact (Week 2–3)

### 2.1 Home Dashboard Refresh
- **Current state**: Static stat cards with placeholder values.
- **Upgrade**:
  - Replace with real-time computed values: `netWorth`, `monthlySpent`, `spendingTrend`.
  - Add mini sparkline chart (3–6 month expense trend) using `fl_chart`.
  - Show 2–3 next upcoming installments with due date and amount.
  - Add "Can I afford this?" button.
- **Effort**: ~4 hours. **Impact**: Dashboard becomes actionable.
- **Files to create/modify**:
  - `lib/features/home/home_screen.dart` (refactor ~200 lines).
  - `lib/core/widgets/sparkline_chart.dart` (new, ~80 lines, wraps `fl_chart`).
  - `lib/features/home/home_notifier.dart` or equivalent (new provider for home state).

### 2.2 Advanced Reports Enhancements
- **Current state**: Basic spending reports exist; heatmap and thermometer missing.
- **Upgrade**:
  - Add **Category Heatmap**: spending by category × month (matrix visualization using `fl_chart` or custom canvas).
  - Add **Debt Thermometer**: per-loan progress bar (paid ÷ total = fill %).
  - Ensure **Budget vs Actual** charts are fully implemented.
  - Cache expensive aggregations (heatmap data, etc.) in `reportsCacheProvider`.
- **Effort**: ~5 hours. **Impact**: Insights into patterns.
- **Files to create/modify**:
  - `lib/features/reports/screens/advanced_reports_screen.dart` (refactor ~150 lines).
  - `lib/core/widgets/category_heatmap.dart` (new, ~120 lines).
  - `lib/core/widgets/debt_thermometer.dart` (new, ~80 lines).
  - `lib/core/compute/reports_compute.dart` (extend heatmap aggregation, ~50 lines).

### 2.3 Backup & Restore (Local Export/Import)
- **Current state**: No backup feature.
- **Upgrade**:
  - Create `lib/features/settings/backup_restore_service.dart`:
    - `exportData() → CompressedPayload` (JSON zip of all tables).
    - `importData(payload, mode: 'replace'|'merge') → void`.
  - Screen: `lib/features/settings/screens/backup_restore_screen.dart`.
  - Validate checksums; warn on conflicts.
- **Effort**: ~5 hours. **Impact**: Data safety and portability.
- **Files to create/modify**:
  - `lib/features/settings/backup_restore_service.dart` (new, ~200 lines).
  - `lib/features/settings/screens/backup_restore_screen.dart` (new, ~250 lines).
  - `lib/core/models/backup_payload.dart` (new DTO, ~40 lines).

---

## Phase 3: Advanced Features (Week 3–4)

### 3.1 CSV/JSON Import Wizard
- **Current state**: No import feature.
- **Upgrade**:
  - Create `lib/features/import_export/csv_json_importer.dart`:
    - Parse CSV/JSON file.
    - Show column-to-field mapping UI.
    - Validate and insert/merge.
  - Screen: `lib/features/import_export/screens/import_wizard_screen.dart` (multi-step form).
- **Effort**: ~6 hours. **Impact**: Easy data onboarding.
- **Files to create/modify**:
  - `lib/features/import_export/csv_json_importer.dart` (new, ~250 lines).
  - `lib/features/import_export/screens/import_wizard_screen.dart` (new, ~300 lines).
  - `lib/features/import_export/models/import_mapping.dart` (new DTO, ~30 lines).

### 3.2 Transfer via QR Code (Multi-Frame)
- **Current state**: No transfer feature.
- **Upgrade**:
  - Use existing camera/QR scanner (if integrated) or add `qr` package.
  - `lib/features/settings/transfer_service.dart`:
    - Chunk payload into QR-sized segments (~2KB each).
    - Generate frames with index/total.
  - Sender screen: generate QR sequence, display with progress.
  - Receiver screen: scan frames, reassemble, validate checksum, import.
- **Effort**: ~7–8 hours. **Impact**: Peer-to-peer data sharing (nice-to-have).
- **Files to create/modify**:
  - `lib/features/settings/transfer_service.dart` (new, ~200 lines).
  - `lib/features/settings/screens/transfer_send_screen.dart` (new, ~200 lines).
  - `lib/features/settings/screens/transfer_receive_screen.dart` (new, ~200 lines).

### 3.3 Optional: TFLite On-Device Classification
- **Current state**: Categorization is rule-based only.
- **Upgrade**:
  - If package size/perf allow: add `tflite_flutter` (or equivalent small model).
  - Train a tiny model (~0.5–1 MB) offline on mock data: payee → category.
  - Feature engineering: payee embedding (TF-IDF or pre-trained), amount bucket, description length.
  - Load model at app startup; call during categorization.
  - Fallback to rule-based if model unavailable.
- **Effort**: ~8–10 hours (including model training/optimization). **Impact**: Better accuracy; "magic" factor.
- **⚠️ Risk**: Increases APK size; requires model training infrastructure. **Recommend**: Do this last if there's appetite.
- **Files to create/modify**:
  - `lib/core/ml/category_classifier.dart` (new, ~100 lines, loads & runs model).
  - `lib/core/ml/models/category_model.tflite` (asset, binary).
  - `lib/features/automation/automation_rules_repository.dart` (integrate classifier, ~5 lines).
  - Model training script (Python, not in repo; can provide template).

---

## Phase 4: Performance & Testing (Week 4+)

### 4.1 Isolate-Based Compute Refactoring
- **Current state**: Many heavy operations already use `compute()`, but not all.
- **Audit**:
  - Identify slow paths: debt projections, heatmap aggregation, cash-flow sim.
  - Move to isolated compute functions if not already done.
  - Profile with `DevTools` → Timeline.
- **Effort**: ~3–4 hours. **Impact**: Smooth UI, no jank.
- **Files to modify**:
  - Extend `lib/core/compute/` with any missing entry points.
  - Add debug logging (wrapped in `kDebugMode`) to log compute times.

### 4.2 Test Coverage Expansion
- **Current state**: Some unit tests exist (`test/`).
- **Upgrade**:
  - Add tests for:
    - Interest calculation (compound, daily accrual).
    - Payoff projections (Snowball vs Avalanche strategies).
    - Budget rollover logic.
    - Smart insights detection.
    - Automation rules matching.
    - Cash-flow simulator edge cases (negative cash, zero income).
  - Target: 70–80% coverage on core logic.
- **Effort**: ~6–8 hours. **Impact**: Confidence in financial correctness.
- **Files to create/modify**:
  - `test/lib/core/compute/interest_test.dart` (new, ~150 lines).
  - `test/lib/core/compute/payoff_test.dart` (new, ~200 lines).
  - `test/lib/features/budget/budget_rollover_test.dart` (new, ~100 lines).
  - `test/lib/features/insights/smart_insights_test.dart` (extend, ~150 lines).
  - `test/lib/features/automation/automation_rules_test.dart` (extend, ~100 lines).

---

## Dependencies to Add (if not present)

| Feature | Package | Version | Notes |
|---------|---------|---------|-------|
| Sparklines | `fl_chart` | ^0.65.0 | Already in use; extend. |
| QR Code Gen/Scan | `qr_flutter`, `mobile_scanner` | ^10.0+ | Optional; only if QR transfer needed. |
| Data Compression | `archive` | ^3.3.0 | For backup/restore zipping. |
| CSV Parsing | `csv` | ^5.0.0+ | For CSV import. |
| TFLite (optional) | `tflite_flutter` | ^0.9.0+ | **Only if classification wanted**. |

---

## Recommended Sequencing (MVP → Full)

### MVP (Week 1)
1. Enhanced auto-categorization dictionary (~4h).
2. Cash-flow simulator + "Can I afford this?" (~6h).
3. Achievements foundation (~5h).
4. **Total**: ~15 hours. **Value**: Core financial decision-making + engagement.

### Phase 2 (Week 2)
5. Home dashboard refresh (~4h).
6. Advanced reports (heatmap, thermometer) (~5h).
7. Backup & Restore (~5h).
8. **Total**: ~14 hours. **Value**: Insights + data safety.

### Phase 3 (Week 3+)
9. CSV/JSON import wizard (~6h).
10. QR transfer (~8h).
11. TFLite classification (optional, ~10h).
12. Isolate optimization + tests (~10h).
13. **Total**: ~34 hours. **Value**: Complete ecosystem + robustness.

---

## Open Questions for User

1. **TFLite classification**: Worth the APK size? Should we include it?
2. **QR transfer**: Is peer-to-peer data sharing essential, or is cloud backup (e.g., Drive/iCloud) preferred? (Current request is offline-only.)
3. **Timeline**: Can you prioritize phases 1–3? Are weeks 1–4 realistic for your team?
4. **Testing**: How deep should test coverage be? 70% or 90%?
5. **Performance**: Are there known slow operations currently? Should we profile first?

---

## Notes for Implementation

- **All computations remain offline** (no cloud APIs, no external services).
- **Caching**: Use Riverpod providers for expensive aggregations (heatmap, cash-flow, projections).
- **UI state**: Prefer ConsumerWidget / ConsumerStatefulWidget for simplicity.
- **Error handling**: Graceful fallbacks if data is corrupted or incomplete.
- **Localization**: Keep Persian/English strings consistent with existing l10n/ structure.
- **DB migrations**: For new fields (e.g., `successCount` in rules), add migration in `DatabaseHelper.onUpgrade()`.

---

## Success Criteria

✓ No new external dependencies requiring API keys or network access.
✓ All operations complete within 2 seconds (UI feels responsive).
✓ Backup/restore preserves all user data with checksums.
✓ "Can I afford this?" matches debt projections within ±1% for simple cases.
✓ Tests pass; no financial edge cases missed.
✓ Home dashboard updates in real-time as user makes changes.

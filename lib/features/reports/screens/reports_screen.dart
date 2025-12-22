// Reports screen: shows overall summaries and filtered installment lists.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/calendar_utils.dart';
import 'package:debt_manager/core/utils/calendar_picker.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/features/shared/summary_cards.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/core/export/export_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:debt_manager/features/achievements/achievements_repository.dart';
import 'package:debt_manager/features/reports/reports_notifier.dart';
import 'package:debt_manager/components/sensitive_text.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);
    final notifier = ref.read(reportsProvider.notifier);
    final exportService = ExportService.instance;

    Future<void> exportCsv() async {
      try {
        final filePath = await exportService.exportInstallmentsCSV(
          fromDate: state.from,
          toDate: state.to,
        );

        if (!context.mounted) return;

        await SharePlus.instance.share(
          ShareParams(files: [XFile(filePath)], text: 'خروجی اقساط'),
        );

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فایل CSV با موفقیت ایجاد و اشتراک‌گذاری شد'),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در ایجاد فایل: $e')));
      }
    }

    Future<void> exportPdf() async {
      try {
        final filePath = await exportService.exportReportPdf();

        if (!context.mounted) return;

        await SharePlus.instance.share(
          ShareParams(files: [XFile(filePath)], text: 'گزارش PDF'),
        );

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فایل PDF با موفقیت ایجاد و اشتراک‌گذاری شد'),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطا در ایجاد فایل PDF: $e')));
      }
    }

    String statusLabel(InstallmentStatus s) {
      switch (s) {
        case InstallmentStatus.paid:
          return 'پرداخت شده';
        case InstallmentStatus.overdue:
          return 'عقب‌افتاده';
        case InstallmentStatus.pending:
          return 'در انتظار';
      }
    }

    Widget rowsSection() {
      if (state.loadingRows) {
        return UIUtils.centeredLoading();
      }
      if (state.rows.isEmpty) {
        return const Center(child: Text('هیچ موردی یافت نشد'));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مجموع برنامه‌ریزی‌شده'),
                      const SizedBox(height: 6),
                      SensitiveText(
                        formatCurrency(
                          state.rows.fold<int>(0, (sum, r) {
                            final inst = r['installment'] as Installment;
                            return sum + inst.amount;
                          }),
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('مجموع پرداخت‌شده'),
                      const SizedBox(height: 6),
                      SensitiveText(
                        formatCurrency(
                          state.rows.fold<int>(0, (sum, r) {
                            final inst = r['installment'] as Installment;
                            if (inst.status == InstallmentStatus.paid) {
                              return sum +
                                  (inst.actualPaidAmount ?? inst.amount);
                            }
                            return sum;
                          }),
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('باقی‌مانده'),
                      const SizedBox(height: 6),
                      SensitiveText(
                        formatCurrency(
                          state.rows.fold<int>(0, (sum, r) {
                                final inst = r['installment'] as Installment;
                                return sum + inst.amount;
                              }) -
                              state.rows.fold<int>(0, (sum, r) {
                                final inst = r['installment'] as Installment;
                                if (inst.status == InstallmentStatus.paid) {
                                  return sum +
                                      (inst.actualPaidAmount ?? inst.amount);
                                }
                                return sum;
                              }),
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...state.rows.map((r) {
            final Installment inst = r['installment'] as Installment;
            final Loan loan = r['loan'] as Loan;
            final cp = state.counterparties.firstWhere(
              (c) => c.id == loan.counterpartyId,
              orElse: () => const Counterparty(id: null, name: 'نامشخص'),
            );

            final cs = Theme.of(context).colorScheme;
            Color statusColor;
            switch (inst.status) {
              case InstallmentStatus.paid:
                statusColor = cs.primary;
                break;
              case InstallmentStatus.overdue:
                statusColor = cs.error;
                break;
              case InstallmentStatus.pending:
                statusColor = cs.secondary;
                break;
            }

            return Card(
              child: ListTile(
                title: ValueListenableBuilder<CalendarType>(
                  valueListenable: SettingsRepository.calendarTypeNotifier,
                  builder: (context, calType, _) {
                    return Text(
                      formatDateForDisplayWithCalendar(
                        _jalaliToGregorianDateTime(inst.dueDateJalali),
                        calType,
                      ),
                    );
                  },
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loan.direction == LoanDirection.borrowed ? 'گرفته‌ام' : 'داده‌ام'} · ${cp.name}${cp.type != null ? ' · ${cp.type}' : ''}${cp.tag != null ? ' · ${cp.tag}' : ''}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusLabel(inst.status),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: statusColor),
                    ),
                  ],
                ),
                trailing: SensitiveText(
                  formatCurrency(inst.amount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }),
        ],
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick actions row
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.pushNamed('advancedReports'),
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('گزارش‌های پیشرفته'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => exportCsv(),
                icon: const Icon(Icons.file_download),
                label: const Text('خروجی CSV'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () async {
                  await exportPdf();
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('گزارش PDF'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          state.loadingSummary
              ? UIUtils.centeredLoading()
              : SummaryCards(
                  borrowed: state.summary?['borrowed'] as int? ?? 0,
                  lent: state.summary?['lent'] as int? ?? 0,
                  net: state.summary?['net'] as int? ?? 0,
                ),
          const SizedBox(height: 12),
          FutureBuilder<List<Achievement>>(
            future: AchievementsRepository.instance.getEarnedAchievements(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }
              final badges = snap.data ?? [];
              if (badges.isEmpty) return const SizedBox.shrink();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نشان‌ها',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (ctx, i) {
                            final a = badges[i];
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircleAvatar(
                                  radius: 22,
                                  child: Icon(Icons.emoji_events, size: 24),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    a.title,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemCount: badges.length,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),
          const Text('فیلترها', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          // Responsive filter row: direction + date pickers + filter sheet
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: Material(
                  type: MaterialType.transparency,
                  child: DropdownButton<LoanDirection?>(
                    value: state.direction,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('همه')),
                      DropdownMenuItem(
                        value: LoanDirection.borrowed,
                        child: Text('گرفته‌ام'),
                      ),
                      DropdownMenuItem(
                        value: LoanDirection.lent,
                        child: Text('داده‌ام'),
                      ),
                    ],
                    onChanged: (v) => notifier.setDirection(v),
                  ),
                ),
              ),
              FilledButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showCalendarAwareDatePicker(
                    context,
                    initialDate: now,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) {
                    if (picked is DateTime) {
                      notifier.setFrom(picked);
                    } else {
                      // Assume Jalali-like object with toDateTime()
                      try {
                        // dynamic to avoid import cycles
                        final dt = picked.toDateTime();
                        notifier.setFrom(dt);
                      } catch (_) {}
                    }
                  }
                },
                child: ValueListenableBuilder<CalendarType>(
                  valueListenable: SettingsRepository.calendarTypeNotifier,
                  builder: (context, calType, _) {
                    return Text(
                      state.from == null
                          ? 'از تاریخ'
                          : formatDateForDisplayWithCalendar(
                              state.from!,
                              calType,
                            ),
                    );
                  },
                ),
              ),
              FilledButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showCalendarAwareDatePicker(
                    context,
                    initialDate: now,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) {
                    if (picked is DateTime) {
                      notifier.setTo(picked);
                    } else {
                      try {
                        final dt = picked.toDateTime();
                        notifier.setTo(dt);
                      } catch (_) {}
                    }
                  }
                },
                child: ValueListenableBuilder<CalendarType>(
                  valueListenable: SettingsRepository.calendarTypeNotifier,
                  builder: (context, calType, _) {
                    return Text(
                      state.to == null
                          ? 'تا تاریخ'
                          : formatDateForDisplayWithCalendar(
                              state.to!,
                              calType,
                            ),
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'فیلترهای بیشتر',
                icon: const Icon(Icons.filter_list),
                onPressed: () async {
                  // show bottom sheet for counterparty/type filters
                  await showModalBottomSheet<void>(
                    context: context,
                    builder: (ctx) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('فیلترهای بیشتر', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            DropdownButton<int?>(
                              value: state.counterpartyFilter,
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('همه')),
                                ...state.counterparties.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                              ],
                              onChanged: (v) => notifier.setCounterpartyFilter(v),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<String?>(
                              value: state.counterpartyTypeFilter,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: null, child: Text('همه انواع')),
                                DropdownMenuItem(value: 'person', child: Text('شخص')),
                                DropdownMenuItem(value: 'bank', child: Text('بانک')),
                                DropdownMenuItem(value: 'company', child: Text('شرکت')),
                              ],
                              onChanged: (v) => notifier.setCounterpartyTypeFilter(v),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('بستن'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          // Status chips and counterparty filter
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: const Text('همه'),
                      selected: state.statusFilter.length ==
                          InstallmentStatus.values.length,
                      onSelected: (v) => notifier.setAllStatuses(v),
                    ),
                    FilterChip(
                      label: const Text('در انتظار'),
                      selected: state.statusFilter.contains(
                        InstallmentStatus.pending,
                      ),
                      onSelected: (v) =>
                          notifier.toggleStatus(InstallmentStatus.pending, v),
                    ),
                    FilterChip(
                      label: const Text('عقب‌افتاده'),
                      selected: state.statusFilter.contains(
                        InstallmentStatus.overdue,
                      ),
                      onSelected: (v) =>
                          notifier.toggleStatus(InstallmentStatus.overdue, v),
                    ),
                    FilterChip(
                      label: const Text('پرداخت شده'),
                      selected: state.statusFilter.contains(
                        InstallmentStatus.paid,
                      ),
                      onSelected: (v) =>
                          notifier.toggleStatus(InstallmentStatus.paid, v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200,
                child: DropdownButton<int?>(
                  value: state.counterpartyFilter,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('همه')),
                    ...state.counterparties.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (v) => notifier.setCounterpartyFilter(v),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: DropdownButton<String?>(
                  value: state.counterpartyTypeFilter,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('همه انواع')),
                    DropdownMenuItem(value: 'person', child: Text('شخص')),
                    DropdownMenuItem(value: 'bank', child: Text('بانک')),
                    DropdownMenuItem(value: 'company', child: Text('شرکت')),
                  ],
                  onChanged: (v) => notifier.setCounterpartyTypeFilter(v),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // rows section
          rowsSection(),
        ],
      ),
    );
  }

  /// Helper to convert Jalali date string (yyyy-MM-dd) to Gregorian DateTime.
  DateTime _jalaliToGregorianDateTime(String jalaliDateStr) {
    try {
      final j = parseJalali(jalaliDateStr);
      final g = j.toGregorian();
      return DateTime(g.year, g.month, g.day);
    } catch (_) {
      // Fallback: treat as already Gregorian
      return DateTime.parse(jalaliDateStr);
    }
  }
}


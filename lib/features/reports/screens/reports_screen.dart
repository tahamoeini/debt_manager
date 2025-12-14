// Reports screen: shows overall summaries and filtered installment lists.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/features/shared/summary_cards.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/features/reports/screens/advanced_reports_screen.dart';
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick actions row
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AdvancedReportsScreen(),
                    ),
                  );
                },
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
                              Text(
                                a.title,
                                style: Theme.of(context).textTheme.bodySmall,
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
        Row(
          children: [
            Expanded(
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
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) notifier.setFrom(picked);
              },
              child: Text(
                state.from == null
                    ? 'از تاریخ'
                    : formatJalaliForDisplay(dateTimeToJalali(state.from!)),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now,
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 5),
                );
                if (picked != null) notifier.setTo(picked);
              },
              child: Text(
                state.to == null
                    ? 'تا تاریخ'
                    : formatJalaliForDisplay(dateTimeToJalali(state.to!)),
              ),
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
                    selected:
                        state.statusFilter.length ==
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
        state.loadingRows
            ? UIUtils.centeredLoading()
            : (state.rows.isEmpty
                  ? const Center(child: Text('هیچ موردی یافت نشد'))
                  : Column(
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
                                          final inst =
                                              r['installment'] as Installment;
                                          return sum + inst.amount;
                                        }),
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
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
                                          final inst =
                                              r['installment'] as Installment;
                                          if (inst.status ==
                                              InstallmentStatus.paid) {
                                            return sum +
                                                (inst.actualPaidAmount ??
                                                    inst.amount);
                                          }
                                          return sum;
                                        }),
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
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
                                              final inst =
                                                  r['installment']
                                                      as Installment;
                                              return sum + inst.amount;
                                            }) -
                                            state.rows.fold<int>(0, (sum, r) {
                                              final inst =
                                                  r['installment']
                                                      as Installment;
                                              if (inst.status ==
                                                  InstallmentStatus.paid) {
                                                return sum +
                                                    (inst.actualPaidAmount ??
                                                        inst.amount);
                                              }
                                              return sum;
                                            }),
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...state.rows.map((r) {
                          final Installment inst =
                              r['installment'] as Installment;
                          final Loan loan = r['loan'] as Loan;
                          final cp = state.counterparties.firstWhere(
                            (c) => c.id == loan.counterpartyId,
                            orElse: () =>
                                const Counterparty(id: null, name: 'نامشخص'),
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
                              title: Text(
                                formatJalaliForDisplay(
                                  parseJalali(inst.dueDateJalali),
                                ),
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
                    )),
      ],
    );
  }
}

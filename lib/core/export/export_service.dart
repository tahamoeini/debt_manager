// Export service: export data as CSV and handle file sharing
import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:debt_manager/core/export/pdf_report_generator.dart';
import 'package:debt_manager/core/db/installment_dao.dart';

class ExportService {
  static final ExportService instance = ExportService._internal();
  ExportService._internal();

  final _db = DatabaseHelper.instance;

  // Export installments as CSV for a given date range
  // Returns the file path of the generated CSV
  Future<String> exportInstallmentsCSV({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    // Load all loans and installments
    final loans = await _db.getAllLoans();
    final counterparties = await _db.getAllCounterparties();

    // Build a map of counterparty id to name
    final cpMap = <int, Counterparty>{};
    for (final cp in counterparties) {
      if (cp.id != null) {
        cpMap[cp.id!] = cp;
      }
    }

    // Collect all installments with their loan info
    final List<List<dynamic>> rows = [];

    // CSV Header
    rows.add([
      'تاریخ سررسید',
      'عنوان وام',
      'جهت',
      'طرف معامله',
      'نوع',
      'مبلغ',
      'وضعیت',
      'تاریخ پرداخت',
      'مبلغ پرداختی',
    ]);

    // Convert date filters to Jalali strings
    final fromStr = fromDate != null
        ? formatJalali(dateTimeToJalali(fromDate))
        : null;
    final toStr = toDate != null
        ? formatJalali(dateTimeToJalali(toDate))
        : null;

    for (final loan in loans) {
      if (loan.id == null) continue;

      final cp = cpMap[loan.counterpartyId];
      final cpName = cp?.name ?? 'نامشخص';
      final cpType = cp?.type ?? '';

      final installments = await _db.getInstallmentsByLoanId(loan.id!);

      for (final inst in installments) {
        // Apply date filter
        final dueDate = inst.dueDateJalali;
        if (fromStr != null && dueDate.compareTo(fromStr) < 0) continue;
        if (toStr != null && dueDate.compareTo(toStr) > 0) continue;

        final direction = loan.direction == LoanDirection.borrowed
            ? 'گرفته‌ام'
            : 'داده‌ام';

        final status = _statusToString(inst.status);

        rows.add([
          formatJalaliForDisplay(parseJalali(inst.dueDateJalali)),
          loan.title,
          direction,
          cpName,
          cpType,
          inst.amount,
          status,
          inst.paidAt ?? '',
          inst.actualPaidAmount ?? '',
        ]);
      }
    }

    // Convert to CSV string
    final csv = const ListToCsvConverter().convert(rows);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/installments_export_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(csv, encoding: utf8);

    return filePath;
  }

  // Generate a professional PDF report (returns file path)
  Future<String> exportReportPdf() async {
    final loans = await _db.getAllLoans();

    // Sum principals by direction
    var totalDebt = 0;
    var totalAssets = 0;
    for (final loan in loans) {
      if (loan.direction == LoanDirection.borrowed) {
        totalDebt += loan.principalAmount;
      } else {
        totalAssets += loan.principalAmount;
      }
    }

    // Get overdue installments from DB
    final db = await _db.database;
    final overdue = await InstallmentDao.getOverdueInstallments(
      db,
      DateTime.now(),
    );

    final bytes = await PdfReportGenerator.instance.generatePdf(
      appName: 'Debt Manager',
      totalDebt: totalDebt,
      totalAssets: totalAssets,
      overdueInstallments: overdue,
    );

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/debt_report_$timestamp.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  // Directly show native print/share sheet with generated PDF.
  Future<void> printReportPdf() async {
    final loans = await _db.getAllLoans();
    var totalDebt = 0;
    var totalAssets = 0;
    for (final loan in loans) {
      if (loan.direction == LoanDirection.borrowed) {
        totalDebt += loan.principalAmount;
      } else {
        totalAssets += loan.principalAmount;
      }
    }

    final db = await _db.database;
    final overdue = await InstallmentDao.getOverdueInstallments(
      db,
      DateTime.now(),
    );

    await PdfReportGenerator.instance.printReport(
      appName: 'Debt Manager',
      totalDebt: totalDebt,
      totalAssets: totalAssets,
      overdueInstallments: overdue,
    );
  }

  String _statusToString(InstallmentStatus status) {
    switch (status) {
      case InstallmentStatus.paid:
        return 'پرداخت شده';
      case InstallmentStatus.overdue:
        return 'عقب‌افتاده';
      case InstallmentStatus.pending:
        return 'در انتظار';
    }
  }

  // Export budgets as CSV
  Future<String> exportBudgetsCSV() async {
    final db = await _db.database;
    final rows = await db.query(
      'budgets',
      orderBy: 'period DESC, category ASC',
    );

    final List<List<dynamic>> csvRows = [];

    // Header
    csvRows.add(['دوره', 'دسته‌بندی', 'مبلغ بودجه', 'انتقال به ماه بعد']);

    for (final row in rows) {
      csvRows.add([
        row['period'],
        row['category'] ?? 'عمومی',
        row['amount'],
        (row['rollover'] as int) == 1 ? 'بله' : 'خیر',
      ]);
    }

    final csv = const ListToCsvConverter().convert(csvRows);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/budgets_export_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsString(csv, encoding: utf8);

    return filePath;
  }
}

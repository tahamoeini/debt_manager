import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/features/loans/models/installment.dart';

// Generates professional PDF reports for legal/formal use.
class PdfReportGenerator {
  PdfReportGenerator._();
  static final instance = PdfReportGenerator._();

  Future<pw.Font> _loadFont() async {
    try {
      final data = await rootBundle.load('assets/fonts/IRANSans.ttf');
      return pw.Font.ttf(data.buffer.asByteData());
    } catch (_) {
      // Fallback to a built-in font if the asset is missing or invalid.
      return pw.Font.helvetica();
    }
  }

  // Build the PDF bytes. All text is rendered RTL and uses the embedded Persian font.
  Future<Uint8List> generatePdf({
    required String appName,
    required int totalDebt,
    required int totalAssets,
    required List<Installment> overdueInstallments,
  }) async {
    final font = await _loadFont();

    final doc = pw.Document();

    final jalaliNow = dateTimeToJalali(DateTime.now());
    final dateStr = formatJalaliForDisplay(jalaliNow);

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      appName,
                      style: pw.TextStyle(font: font, fontSize: 18),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'تاریخ: $dateStr',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Summary table
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.TableHelper.fromTextArray(
                headers: ['عنوان', 'مبلغ'],
                data: [
                  ['بدهی کل', formatCurrency(totalDebt)],
                  ['دارایی کل', formatCurrency(totalAssets)],
                ],
                headerStyle: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
                cellStyle: pw.TextStyle(font: font, fontSize: 12),
                cellAlignment: pw.Alignment.centerRight,
                headerDecoration: const pw.BoxDecoration(
                  color: pdf.PdfColors.grey300,
                ),
                border: null,
              ),
            ),

            pw.SizedBox(height: 18),

            // Overdue Installments Section
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pdf.PdfColors.red, width: 1),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'اقساط معوق',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: pdf.PdfColors.red,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  if (overdueInstallments.isEmpty)
                    pw.Text(
                      'هیچ قسط معوقی وجود ندارد.',
                      style: pw.TextStyle(font: font, fontSize: 12),
                    )
                  else
                    pw.TableHelper.fromTextArray(
                      headers: ['شناسه وام', 'تاریخ سررسید', 'مبلغ', 'وضعیت'],
                      data: overdueInstallments
                          .map(
                            (i) => [
                              i.loanId.toString(),
                              i.dueDateJalali,
                              formatCurrency(i.amount),
                              i.status == InstallmentStatus.overdue
                                  ? 'معوق'
                                  : (i.status == InstallmentStatus.paid
                                      ? 'پرداخت‌شده'
                                      : 'مشخص'),
                            ],
                          )
                          .toList(),
                      headerStyle: pw.TextStyle(
                        font: font,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      cellStyle: pw.TextStyle(font: font, fontSize: 11),
                      cellAlignment: pw.Alignment.centerRight,
                      headerDecoration: const pw.BoxDecoration(
                        color: pdf.PdfColors.grey300,
                      ),
                    ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  // Convenience helper to show native print/share sheet with the generated PDF.
  Future<void> printReport({
    required String appName,
    required int totalDebt,
    required int totalAssets,
    required List<Installment> overdueInstallments,
  }) async {
    final bytes = await generatePdf(
      appName: appName,
      totalDebt: totalDebt,
      totalAssets: totalAssets,
      overdueInstallments: overdueInstallments,
    );

    await Printing.layoutPdf(onLayout: (_) => bytes);
  }
}

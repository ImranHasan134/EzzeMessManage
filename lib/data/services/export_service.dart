import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'db_service.dart';
import '../models/mess_backup.dart';
import '../../core/helpers.dart';
import '../../core/calculation_engine.dart';

class ExportService {
  Future<void> shareJson(String monthId) async {
    final members = dbService.getActiveMembers();
    final meals = dbService.getMealsByMonth(monthId);
    final bazar = dbService.getBazarByMonth(monthId);
    final costs = dbService.getCostsByMonth(monthId);
    final payments = dbService.getPaymentsByMonth(monthId);

    final backup = MessBackup(
      version: '1.0',
      exportedAt: DateTime.now().toIso8601String(),
      monthId: monthId,
      members: members.map((m) => m.toJson()).toList(),
      mealEntries: meals.map((m) => m.toJson()).toList(),
      bazarEntries: bazar.map((b) => b.toJson()).toList(),
      otherCosts: costs.map((c) => c.toJson()).toList(),
      payments: payments.map((p) => p.toJson()).toList(),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/mess_backup_$monthId.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(backup.toJson()));
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'MessManager backup — $monthId',
    );
  }

  Future<void> sharePdf(String monthId) async {
    final summary = computeSummary(monthId);
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) => [
        pw.Text('Mess Report : ${formatMonthId(monthId)}',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(
          'Meal rate: ${summary.mealRate.toStringAsFixed(2)} Tk  |  '
              'Total meals: ${summary.totalMeals}  |  '
              'Bazar: ${summary.totalBazar.toStringAsFixed(0)} Tk  |  '
              'Bazar remaining: ${summary.bazarRemaining.toStringAsFixed(0)} Tk',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.Divider(height: 24),
        ...summary.members.map((ms) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(ms.member.name,
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            _pdfRow('Meals (${ms.totalMeals} × ${summary.mealRate.toStringAsFixed(2)} Tk)',
                '${ms.mealCost.toStringAsFixed(0)} Tk'),
            _pdfRow('Other costs', '${ms.otherCosts.toStringAsFixed(0)} Tk'),
            _pdfRow('Total cost', '${ms.totalCost.toStringAsFixed(0)} Tk', bold: true),
            _pdfRow('Paid', '${ms.paid.toStringAsFixed(0)} Tk'),
            _pdfRow(
              ms.hasDue
                  ? 'Due'
                  : ms.isOverpaid
                  ? 'Advance'
                  : 'Settled',
              '${ms.due.abs().toStringAsFixed(0)} Tk',
              bold: true,
              color: ms.hasDue
                  ? PdfColors.red700
                  : ms.isOverpaid
                  ? PdfColors.blue700
                  : PdfColors.green700,
            ),
            pw.Divider(height: 20),
          ],
        )),
      ],
    ));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'mess_report_$monthId.pdf');
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false, PdfColor? color}) {
    final style = pw.TextStyle(
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(value, style: style)],
      ),
    );
  }
}

final exportService = ExportService();
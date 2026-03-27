import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/mess_backup.dart';
import '../models/member.dart';
import '../models/meal_entry.dart';
import '../models/bazar_entry.dart';
import '../models/other_cost.dart';
import '../models/payment.dart';
import 'db_service.dart';

class ImportResult {
  final bool success;
  final String message;
  final MessBackup? backup;
  ImportResult({required this.success, required this.message, this.backup});
}

class ImportService {
  Future<ImportResult> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Select MessManager backup (.json)',
    );

    if (result == null || result.files.isEmpty) {
      return ImportResult(success: false, message: 'No file selected.');
    }

    final path = result.files.single.path;
    if (path == null) return ImportResult(success: false, message: 'Cannot read file path.');

    String raw;
    try {
      raw = await File(path).readAsString();
    } catch (e) {
      return ImportResult(success: false, message: 'Cannot read file: $e');
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw);
    } catch (_) {
      return ImportResult(success: false, message: 'Invalid JSON. Is this a MessManager backup?');
    }

    if (!json.containsKey('monthId') || !json.containsKey('version')) {
      return ImportResult(success: false, message: 'Not a valid MessManager backup file.');
    }

    try {
      final backup = MessBackup.fromJson(json);
      return ImportResult(
          success: true, message: 'Ready to import ${backup.monthId}', backup: backup);
    } catch (e) {
      return ImportResult(success: false, message: 'Parse error: $e');
    }
  }

  void commitImport(MessBackup backup) {
    dbService.clearMonth(backup.monthId);
    for (final m in backup.members) {
      dbService.saveMember(Member.fromJson(m));
    }
    for (final m in backup.mealEntries) {
      dbService.saveMeal(MealEntry.fromJson(m));
    }
    for (final b in backup.bazarEntries) {
      dbService.saveBazar(BazarEntry.fromJson(b));
    }
    for (final c in backup.otherCosts) {
      dbService.saveCost(OtherCost.fromJson(c));
    }
    for (final p in backup.payments) {
      dbService.savePayment(Payment.fromJson(p));
    }
  }
}

final importService = ImportService();
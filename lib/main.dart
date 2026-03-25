// ============================================================
// MessManager — main.dart  (ObjectBox edition)
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'objectbox.g.dart';

// ============================================================
// SECTION 1 — OBJECTBOX MODELS
// ============================================================

@Entity()
class Member {
  @Id()
  int id = 0;
  late String name;
  late String initials;
  late String avatarColor;
  bool isActive = true;
  late String joinedMonthId;
  DateTime? createdAt;

  Member({
    this.id = 0,
    this.name = '',
    this.initials = '',
    this.avatarColor = '7F77DD',
    this.isActive = true,
    this.joinedMonthId = '',
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'initials': initials,
    'avatarColor': avatarColor,
    'isActive': isActive,
    'joinedMonthId': joinedMonthId,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Member.fromJson(Map<String, dynamic> j) => Member(
    name: j['name'] ?? '',
    initials: j['initials'] ?? '',
    avatarColor: j['avatarColor'] ?? '7F77DD',
    isActive: j['isActive'] ?? true,
    joinedMonthId: j['joinedMonthId'] ?? '',
    createdAt: j['createdAt'] != null ? DateTime.parse(j['createdAt']) : null,
  );
}

@Entity()
class MealEntry {
  @Id()
  int id = 0;
  late int memberId;
  late int count;
  @Property(type: PropertyType.date)
  late DateTime date;
  late String monthId;

  MealEntry({
    this.id = 0,
    this.memberId = 0,
    this.count = 0,
    DateTime? date,
    this.monthId = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'count': count,
    'date': date.toIso8601String(),
    'monthId': monthId,
  };

  factory MealEntry.fromJson(Map<String, dynamic> j) => MealEntry(
    memberId: j['memberId'] ?? 0,
    count: j['count'] ?? 0,
    date: DateTime.parse(j['date']),
    monthId: j['monthId'] ?? '',
  );
}

@Entity()
class BazarEntry {
  @Id()
  int id = 0;
  late double amount;
  late String note;
  late String category;
  @Property(type: PropertyType.date)
  late DateTime date;
  late String monthId;

  BazarEntry({
    this.id = 0,
    this.amount = 0,
    this.note = '',
    this.category = 'General',
    DateTime? date,
    this.monthId = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'note': note,
    'category': category,
    'date': date.toIso8601String(),
    'monthId': monthId,
  };

  factory BazarEntry.fromJson(Map<String, dynamic> j) => BazarEntry(
    amount: (j['amount'] as num).toDouble(),
    note: j['note'] ?? '',
    category: j['category'] ?? 'General',
    date: DateTime.parse(j['date']),
    monthId: j['monthId'] ?? '',
  );
}

@Entity()
class OtherCost {
  @Id()
  int id = 0;
  late int memberId;
  late double amount;
  late String category;
  late String note;
  @Property(type: PropertyType.date)
  late DateTime date;
  late String monthId;

  OtherCost({
    this.id = 0,
    this.memberId = 0,
    this.amount = 0,
    this.category = 'Rent',
    this.note = '',
    DateTime? date,
    this.monthId = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'amount': amount,
    'category': category,
    'note': note,
    'date': date.toIso8601String(),
    'monthId': monthId,
  };

  factory OtherCost.fromJson(Map<String, dynamic> j) => OtherCost(
    memberId: j['memberId'] ?? 0,
    amount: (j['amount'] as num).toDouble(),
    category: j['category'] ?? 'Rent',
    note: j['note'] ?? '',
    date: DateTime.parse(j['date']),
    monthId: j['monthId'] ?? '',
  );
}

@Entity()
class Payment {
  @Id()
  int id = 0;
  late int memberId;
  late double amount;
  late String method;
  late String note;
  @Property(type: PropertyType.date)
  late DateTime date;
  late String monthId;

  Payment({
    this.id = 0,
    this.memberId = 0,
    this.amount = 0,
    this.method = 'Cash',
    this.note = '',
    DateTime? date,
    this.monthId = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'amount': amount,
    'method': method,
    'note': note,
    'date': date.toIso8601String(),
    'monthId': monthId,
  };

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
    memberId: j['memberId'] ?? 0,
    amount: (j['amount'] as num).toDouble(),
    method: j['method'] ?? 'Cash',
    note: j['note'] ?? '',
    date: DateTime.parse(j['date']),
    monthId: j['monthId'] ?? '',
  );
}

// ============================================================
// SECTION 2 — OBJECTBOX STORE SINGLETON
// ============================================================

late Store _store;

Future<void> _initStore() async {
  final dir = await getApplicationDocumentsDirectory();
  _store = await openStore(directory: '${dir.path}/mess_ob');
}

Box<Member> get _memberBox => _store.box<Member>();
Box<MealEntry> get _mealBox => _store.box<MealEntry>();
Box<BazarEntry> get _bazarBox => _store.box<BazarEntry>();
Box<OtherCost> get _costBox => _store.box<OtherCost>();
Box<Payment> get _paymentBox => _store.box<Payment>();

// ============================================================
// SECTION 3 — DATABASE SERVICE
// ============================================================

class DbService {
  List<Member> getActiveMembers() =>
      _memberBox.getAll().where((m) => m.isActive).toList();

  void saveMember(Member m) => _memberBox.put(m);

  void softDeleteMember(int id) {
    final m = _memberBox.get(id);
    if (m != null) {
      m.isActive = false;
      _memberBox.put(m);
    }
  }

  List<MealEntry> getMealsByMonth(String monthId) =>
      _mealBox.getAll().where((e) => e.monthId == monthId).toList();

  void saveMeal(MealEntry e) => _mealBox.put(e);
  void deleteMeal(int id) => _mealBox.remove(id);

  List<BazarEntry> getBazarByMonth(String monthId) =>
      _bazarBox.getAll().where((e) => e.monthId == monthId).toList();

  void saveBazar(BazarEntry e) => _bazarBox.put(e);
  void deleteBazar(int id) => _bazarBox.remove(id);

  List<OtherCost> getCostsByMonth(String monthId) =>
      _costBox.getAll().where((e) => e.monthId == monthId).toList();

  void saveCost(OtherCost e) => _costBox.put(e);
  void deleteCost(int id) => _costBox.remove(id);

  List<Payment> getPaymentsByMonth(String monthId) =>
      _paymentBox.getAll().where((e) => e.monthId == monthId).toList();

  void savePayment(Payment e) => _paymentBox.put(e);
  void deletePayment(int id) => _paymentBox.remove(id);

  List<String> getAllMonthIds() {
    final ids = _mealBox.getAll().map((e) => e.monthId).toSet().toList();
    ids.sort((a, b) => b.compareTo(a));
    return ids;
  }

  void clearMonth(String monthId) {
    final mealIds = _mealBox.getAll().where((e) => e.monthId == monthId).map((e) => e.id).toList();
    final bazarIds = _bazarBox.getAll().where((e) => e.monthId == monthId).map((e) => e.id).toList();
    final costIds = _costBox.getAll().where((e) => e.monthId == monthId).map((e) => e.id).toList();
    final payIds = _paymentBox.getAll().where((e) => e.monthId == monthId).map((e) => e.id).toList();
    _mealBox.removeMany(mealIds);
    _bazarBox.removeMany(bazarIds);
    _costBox.removeMany(costIds);
    _paymentBox.removeMany(payIds);
  }
}

final _db = DbService();

// ============================================================
// SECTION 4 — CALCULATION ENGINE
// ============================================================

class MemberSummary {
  final Member member;
  final int totalMeals;
  final double mealCost;
  final double otherCosts;
  final double totalCost;
  final double paid;
  final double due;

  MemberSummary({
    required this.member,
    required this.totalMeals,
    required this.mealCost,
    required this.otherCosts,
    required this.totalCost,
    required this.paid,
    required this.due,
  });

  bool get isSettled => due.abs() < 0.01;
  bool get isOverpaid => due < -0.01;
  bool get hasDue => due > 0.01;
}

class MonthSummary {
  final double totalBazar;
  final int totalMeals;
  final double mealRate;
  final double totalPaid;
  final double totalOtherCosts;
  final double bazarBudget;
  final double bazarRemaining;
  final double totalDue;
  final List<MemberSummary> members;

  MonthSummary({
    required this.totalBazar,
    required this.totalMeals,
    required this.mealRate,
    required this.totalPaid,
    required this.totalOtherCosts,
    required this.bazarBudget,
    required this.bazarRemaining,
    required this.totalDue,
    required this.members,
  });
}

MonthSummary computeSummary(String monthId) {
  final members = _db.getActiveMembers();
  final meals = _db.getMealsByMonth(monthId);
  final bazar = _db.getBazarByMonth(monthId);
  final costs = _db.getCostsByMonth(monthId);
  final payments = _db.getPaymentsByMonth(monthId);

  final totalBazar = bazar.fold(0.0, (s, b) => s + b.amount);
  final totalMeals = meals.fold(0, (s, m) => s + m.count);
  final mealRate = totalMeals > 0 ? totalBazar / totalMeals : 0.0;
  final totalPaid = payments.fold(0.0, (s, p) => s + p.amount);
  final totalOtherCosts = costs.fold(0.0, (s, c) => s + c.amount);
  final bazarBudget = totalPaid - totalOtherCosts;
  final bazarRemaining = bazarBudget - totalBazar;

  final summaries = members.map((member) {
    final mCount = meals.where((m) => m.memberId == member.id).fold(0, (s, m) => s + m.count);
    final mCost = mCount * mealRate;
    final oCost = costs.where((c) => c.memberId == member.id).fold(0.0, (s, c) => s + c.amount);
    final paidAmt = payments.where((p) => p.memberId == member.id).fold(0.0, (s, p) => s + p.amount);
    return MemberSummary(
      member: member,
      totalMeals: mCount,
      mealCost: mCost,
      otherCosts: oCost,
      totalCost: mCost + oCost,
      paid: paidAmt,
      due: mCost + oCost - paidAmt,
    );
  }).toList();

  return MonthSummary(
    totalBazar: totalBazar,
    totalMeals: totalMeals,
    mealRate: mealRate,
    totalPaid: totalPaid,
    totalOtherCosts: totalOtherCosts,
    bazarBudget: bazarBudget,
    bazarRemaining: bazarRemaining,
    totalDue: summaries.where((s) => s.hasDue).fold(0.0, (s, m) => s + m.due),
    members: summaries,
  );
}

// ============================================================
// SECTION 5 — BACKUP MODEL
// ============================================================

class MessBackup {
  final String version;
  final String exportedAt;
  final String monthId;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> mealEntries;
  final List<Map<String, dynamic>> bazarEntries;
  final List<Map<String, dynamic>> otherCosts;
  final List<Map<String, dynamic>> payments;

  MessBackup({
    required this.version,
    required this.exportedAt,
    required this.monthId,
    required this.members,
    required this.mealEntries,
    required this.bazarEntries,
    required this.otherCosts,
    required this.payments,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt,
    'monthId': monthId,
    'members': members,
    'mealEntries': mealEntries,
    'bazarEntries': bazarEntries,
    'otherCosts': otherCosts,
    'payments': payments,
  };

  factory MessBackup.fromJson(Map<String, dynamic> j) => MessBackup(
    version: j['version'] ?? '1.0',
    exportedAt: j['exportedAt'] ?? '',
    monthId: j['monthId'] ?? '',
    members: List<Map<String, dynamic>>.from(j['members'] ?? []),
    mealEntries: List<Map<String, dynamic>>.from(j['mealEntries'] ?? []),
    bazarEntries: List<Map<String, dynamic>>.from(j['bazarEntries'] ?? []),
    otherCosts: List<Map<String, dynamic>>.from(j['otherCosts'] ?? []),
    payments: List<Map<String, dynamic>>.from(j['payments'] ?? []),
  );
}

// ============================================================
// SECTION 6 — EXPORT SERVICE
// ============================================================

class ExportService {
  Future<void> shareJson(String monthId) async {
    final members = _db.getActiveMembers();
    final meals = _db.getMealsByMonth(monthId);
    final bazar = _db.getBazarByMonth(monthId);
    final costs = _db.getCostsByMonth(monthId);
    final payments = _db.getPaymentsByMonth(monthId);

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
        pw.Text('Mess Report — ${_formatMonthId(monthId)}',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(
          'Meal rate: ৳${summary.mealRate.toStringAsFixed(2)}  |  '
              'Total meals: ${summary.totalMeals}  |  '
              'Bazar: ৳${summary.totalBazar.toStringAsFixed(0)}  |  '
              'Bazar remaining: ৳${summary.bazarRemaining.toStringAsFixed(0)}',
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.Divider(height: 24),
        ...summary.members.map((ms) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(ms.member.name,
                style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            _pdfRow('Meals (${ms.totalMeals} × ৳${summary.mealRate.toStringAsFixed(2)})',
                '৳${ms.mealCost.toStringAsFixed(0)}'),
            _pdfRow('Other costs', '৳${ms.otherCosts.toStringAsFixed(0)}'),
            _pdfRow('Total cost', '৳${ms.totalCost.toStringAsFixed(0)}', bold: true),
            _pdfRow('Paid', '৳${ms.paid.toStringAsFixed(0)}'),
            _pdfRow(
              ms.hasDue
                  ? 'Due'
                  : ms.isOverpaid
                  ? 'Advance'
                  : 'Settled',
              '৳${ms.due.abs().toStringAsFixed(0)}',
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

// ============================================================
// SECTION 7 — IMPORT SERVICE
// ============================================================

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
    _db.clearMonth(backup.monthId);
    for (final m in backup.members) {
      _memberBox.put(Member.fromJson(m));
    }
    for (final m in backup.mealEntries) {
      _mealBox.put(MealEntry.fromJson(m));
    }
    for (final b in backup.bazarEntries) {
      _bazarBox.put(BazarEntry.fromJson(b));
    }
    for (final c in backup.otherCosts) {
      _costBox.put(OtherCost.fromJson(c));
    }
    for (final p in backup.payments) {
      _paymentBox.put(Payment.fromJson(p));
    }
  }
}

final _exportSvc = ExportService();
final _importSvc = ImportService();

// ============================================================
// SECTION 8 — HELPERS
// ============================================================

String _currentMonthId() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}';
}

String _formatMonthId(String id) {
  final parts = id.split('-');
  if (parts.length != 2) return id;
  const months = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  final m = int.tryParse(parts[1]) ?? 0;
  return '${months[m]} ${parts[0]}';
}

// ============================================================
// SECTION 9 — APP ENTRY & THEME
// ============================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initStore();
  runApp(const MessManagerApp());
}

class MessManagerApp extends StatefulWidget {
  const MessManagerApp({super.key});
  @override
  State<MessManagerApp> createState() => _MessManagerAppState();
}

class _MessManagerAppState extends State<MessManagerApp> {
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _isDark = prefs.getBool('isDark') ?? false);
  }

  Future<void> _toggleTheme(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', val);
    if (mounted) setState(() => _isDark = val);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MessManager',
      debugShowCheckedModeBanner: false,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: MainShell(isDark: _isDark, onThemeToggle: _toggleTheme),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    const seedColor = Color(0xFF4F46E5); // Premium Indigo
    final isDark = brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        background: bgColor,
        surface: surfaceColor,
      ),
      scaffoldBackgroundColor: bgColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        color: surfaceColor,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: seedColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(fontSize: 14),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: surfaceColor,
        indicatorColor: seedColor.withOpacity(0.15),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
        }),
      ),
    );
  }
}

// ============================================================
// SECTION 10 — MAIN SHELL
// ============================================================

class MainShell extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeToggle;
  const MainShell({super.key, required this.isDark, required this.onThemeToggle});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final String _monthId = _currentMonthId();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildScreen() {
    final od = openDrawer;
    switch (_index) {
      case 0:
        return HomeScreen(monthId: _monthId, openDrawer: od);
      case 1:
        return MealScreen(monthId: _monthId, openDrawer: od);
      case 2:
        return BazarScreen(monthId: _monthId, openDrawer: od);
      case 3:
        return OtherCostScreen(monthId: _monthId, openDrawer: od);
      case 4:
        return PaymentScreen(monthId: _monthId, openDrawer: od);
      case 5:
        return HistoryScreen(currentMonthId: _monthId, openDrawer: od);
      case 6:
        return SettingsScreen(
            isDark: widget.isDark, onThemeToggle: widget.onThemeToggle, openDrawer: od);
      default:
        return HomeScreen(monthId: _monthId, openDrawer: od);
    }
  }

  void _navigate(int index) {
    setState(() => _index = index);
    Navigator.pop(context);
  }

  void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  Widget _drawerTile(String label, IconData icon, int index) {
    final selected = _index == index;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon, color: selected ? theme.colorScheme.primary : theme.iconTheme.color),
        title: Text(label,
            style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? theme.colorScheme.primary : null)),
        selected: selected,
        selectedTileColor: theme.colorScheme.primaryContainer.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => _navigate(index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = _formatMonthId(_monthId);
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 32,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.home_work_rounded, color: theme.colorScheme.primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text('MessManager',
                      style: TextStyle(
                          color: theme.textTheme.titleLarge?.color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(monthLabel,
                      style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  children: [
                    _drawerTile('Other costs', Icons.receipt_long_rounded, 3),
                    _drawerTile('Payments', Icons.payments_rounded, 4),
                    _drawerTile('History', Icons.history_rounded, 5),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1),
                    ),
                    _drawerTile('Settings', Icons.settings_rounded, 6),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('v1.0.0 · Local-first',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.withOpacity(0.6))),
            ),
          ],
        ),
      ),
      body: _buildScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index.clamp(0, 2),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_outlined),
              selectedIcon: Icon(Icons.restaurant_rounded),
              label: 'Meals'),
          NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Bazar'),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 11 — HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  final String monthId;
  final VoidCallback openDrawer;
  const HomeScreen({super.key, required this.monthId, required this.openDrawer});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MonthSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _loading = true);
    final s = computeSummary(widget.monthId);
    setState(() {
      _summary = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.openDrawer),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dashboard'),
          Text(_formatMonthId(widget.monthId),
              style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
              tooltip: 'Refresh')
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_summary != null) ...[
              _buildSummaryCards(_summary!),
              const SizedBox(height: 24),
              Row(children: [
                Text('MEMBERS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('${_summary!.members.length} Active',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary)),
                ),
              ]),
              const SizedBox(height: 12),
              ..._summary!.members.map(_buildMemberCard),
              if (_summary!.members.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.people_outline, size: 32, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      const Text('No members yet',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      const Text('Go to Settings to add your first member.',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ]),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(MonthSummary s) {
    final remaining = s.bazarRemaining;
    final remainingColor = remaining >= 0 ? Colors.teal : Colors.redAccent;

    return Column(children: [
      Row(children: [
        Expanded(child: _metricCard('Meal Rate', '৳${s.mealRate.toStringAsFixed(2)}', 'Per meal', Icons.restaurant_menu_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _metricCard('Total Meals', '${s.totalMeals}', 'This month', Icons.tag_rounded)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _metricCard('Bazar Spent', '৳${s.totalBazar.toStringAsFixed(0)}', widget.monthId, Icons.shopping_basket_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _metricCard('Budget', '৳${s.bazarBudget.toStringAsFixed(0)}', 'Paid − Fixed', Icons.account_balance_wallet_rounded)),
      ]),
      const SizedBox(height: 12),
      _metricCard(
        'Bazar Remaining',
        '৳${remaining.abs().toStringAsFixed(0)}',
        remaining >= 0 ? 'Surplus in the pool' : 'Pool is overspent',
        Icons.analytics_rounded,
        color: remainingColor,
        full: true,
      ),
    ]);
  }

  Widget _metricCard(String label, String value, String sub, IconData icon,
      {Color? color, bool full = false}) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: full ? 28 : 22, fontWeight: FontWeight.bold, color: cardColor)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(MemberSummary ms) {
    final theme = Theme.of(context);
    final color = ms.hasDue ? Colors.redAccent : ms.isOverpaid ? Colors.blueAccent : Colors.teal;
    final label = ms.hasDue
        ? '৳${ms.due.toStringAsFixed(0)} Due'
        : ms.isOverpaid
        ? '+৳${ms.due.abs().toStringAsFixed(0)}'
        : 'Settled';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showMemberDetail(ms),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(ms.member.initials,
                      style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ms.member.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${ms.totalMeals} meals',
                          style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        ms.hasDue ? 'Owes' : ms.isOverpaid ? 'Overpaid' : 'Clear',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMemberDetail(MemberSummary ms) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(ms.member.initials,
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
            ),
            const SizedBox(height: 16),
            Text(ms.member.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05))
              ),
              child: Column(
                children: [
                  _detailRow('Meal Cost (${ms.totalMeals})', '৳${ms.mealCost.toStringAsFixed(0)}'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                  _detailRow('Other Costs', '৳${ms.otherCosts.toStringAsFixed(0)}'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                  _detailRow('Total Cost', '৳${ms.totalCost.toStringAsFixed(0)}', bold: true),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                  _detailRow('Total Paid', '৳${ms.paid.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ms.hasDue ? Colors.redAccent.withOpacity(0.1) : (ms.isOverpaid ? Colors.blueAccent.withOpacity(0.1) : Colors.teal.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: _detailRow(
                ms.hasDue ? 'Final Due' : ms.isOverpaid ? 'Advance Paid' : 'Status',
                ms.hasDue || ms.isOverpaid ? '৳${ms.due.abs().toStringAsFixed(0)}' : 'Settled',
                bold: true,
                color: ms.hasDue ? Colors.redAccent : ms.isOverpaid ? Colors.blueAccent : Colors.teal,
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false, Color? color}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: TextStyle(
              color: color ?? Colors.grey,
              fontSize: 15,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500)),
      Text(value,
          style: TextStyle(
              color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 15,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600)),
    ]);
  }
}

// ============================================================
// SECTION 12 — MEAL SCREEN
// ============================================================

class MealScreen extends StatefulWidget {
  final String monthId;
  final VoidCallback openDrawer;
  const MealScreen({super.key, required this.monthId, required this.openDrawer});
  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  List<Member> _members = [];
  final Map<int, int> _counts = {};
  DateTime _date = DateTime.now();
  List<MealEntry> _allMonthEntries = [];
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final members = _db.getActiveMembers();
    final all = _db.getMealsByMonth(widget.monthId);
    setState(() {
      _members = members;
      final updatedCounts = <int, int>{};
      for (final m in members) {
        updatedCounts[m.id] = _counts[m.id] ?? 0;
      }
      _counts
        ..clear()
        ..addAll(updatedCounts);
      _allMonthEntries = all;
    });
  }

  void _save() {
    final snapshot = Map<int, int>.from(_counts);
    int saved = 0;
    for (final member in _members) {
      final count = snapshot[member.id] ?? 0;
      if (count > 0) {
        _db.saveMeal(
            MealEntry(memberId: member.id, count: count, date: _date, monthId: widget.monthId));
        saved++;
      }
    }
    if (saved == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Nothing to save — all counts are 0'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.orange.shade800));
      return;
    }
    for (final key in _counts.keys.toList()) {
      _counts[key] = 0;
    }
    _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved $saved member${saved > 1 ? "s" : ""} meals for ${_date.day}/${_date.month}!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  int _mealCountOn(int memberId, int day) {
    final year = int.parse(widget.monthId.split('-')[0]);
    final month = int.parse(widget.monthId.split('-')[1]);
    return _allMonthEntries
        .where((e) =>
    e.memberId == memberId &&
        e.date.year == year &&
        e.date.month == month &&
        e.date.day == day)
        .fold(0, (s, e) => s + e.count);
  }

  int _daysInMonth() {
    final year = int.parse(widget.monthId.split('-')[0]);
    final month = int.parse(widget.monthId.split('-')[1]);
    return DateTime(year, month + 1, 0).day;
  }

  int _totalForMember(int memberId) =>
      _allMonthEntries.where((e) => e.memberId == memberId).fold(0, (s, e) => s + e.count);

  @override
  Widget build(BuildContext context) {
    final total = _counts.values.fold(0, (s, v) => s + v);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.openDrawer),
        title: const Text('Meal Entry'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              icon: Icon(_showCalendar ? Icons.list_rounded : Icons.calendar_month_rounded, size: 20),
              label: Text(_showCalendar ? 'Entry' : 'Calendar'),
              onPressed: () => setState(() => _showCalendar = !_showCalendar),
            ),
          ),
        ],
      ),
      body: _showCalendar ? _buildCalendarView(theme) : _buildEntryView(total),
    );
  }

  Widget _buildEntryView(int total) {
    if (_members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.people_outline, size: 56, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text('No members yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Go to Settings to add your first member.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.settings_rounded, size: 20),
              label: const Text('Go to Settings'),
              onPressed: () {
                final shell = context.findAncestorStateOfType<_MainShellState>();
                shell?.setState(() => shell._index = 6);
              },
            ),
          ]),
        ),
      );
    }

    final theme = Theme.of(context);

    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
          ),
          title: Text('${_date.day} / ${_date.month} / ${_date.year}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: const Text('Tap to change date', style: TextStyle(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () async {
            final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2024),
                lastDate: DateTime.now());
            if (d != null) setState(() => _date = d);
          },
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                const Expanded(
                    child: Text('MEMBER',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.5))),
                SizedBox(
                    width: 140,
                    child: const Text('MEALS TODAY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.5))),
              ]),
            ),
            const Divider(height: 1),
            ...List.generate(_members.length, (i) {
              final m = _members[i];
              final count = _counts[m.id] ?? 0;
              return Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: i < _members.length - 1
                            ? BorderSide(color: Colors.grey.withOpacity(0.15), width: 1)
                            : BorderSide.none)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(m.initials,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Text(m.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),

                  // Refined Stepper
                  Container(
                    decoration: BoxDecoration(
                        color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(24)
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_rounded, color: count > 0 ? theme.colorScheme.primary : Colors.grey),
                          onPressed: count > 0 ? () => setState(() => _counts[m.id] = count - 1) : null,
                          splashRadius: 20,
                        ),
                        SizedBox(
                          width: 24,
                          child: Text('$count',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: count > 0 ? theme.colorScheme.primary : Colors.grey)),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
                          onPressed: () => setState(() => _counts[m.id] = count + 1),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Today', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                Text('$total meals',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              FilledButton.icon(
                icon: const Icon(Icons.save_rounded, size: 20),
                label: const Text('Save Meals'),
                onPressed: total > 0 ? _save : null,
              ),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      Text('MONTHLY TOTALS',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _members.map((m) {
              final tot = _totalForMember(m.id);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
                      child: Text(m.initials,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(m.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: tot > 0
                            ? theme.colorScheme.primaryContainer
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('$tot meals',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: tot > 0 ? theme.colorScheme.primary : Colors.grey)),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ),
    ]);
  }

  Widget _buildCalendarView(ThemeData theme) {
    final days = _daysInMonth();
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);
    final altRowBg = isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              border: TableBorder.symmetric(inside: BorderSide(color: borderColor, width: 1)),
              defaultColumnWidth: const FixedColumnWidth(56),
              columnWidths: {
                0: const FixedColumnWidth(90),
                ..._members.asMap().map((i, _) => MapEntry(i + 1, const FixedColumnWidth(64))),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.3)),
                  children: [
                    _cell('Date', isHeader: true, theme: theme),
                    ..._members.map((m) => _cell(m.initials, isHeader: true, small: false, theme: theme)),
                  ],
                ),
                ...List.generate(days, (i) {
                  final day = i + 1;
                  final year = int.parse(widget.monthId.split('-')[0]);
                  final month = int.parse(widget.monthId.split('-')[1]);
                  final date = DateTime(year, month, day);
                  final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
                  final isFriday = date.weekday == 5;
                  final rowBg = isFriday
                      ? Colors.orangeAccent.withOpacity(isDark ? 0.1 : 0.05)
                      : i.isOdd
                      ? altRowBg
                      : null;

                  return TableRow(
                    decoration: rowBg != null ? BoxDecoration(color: rowBg) : null,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Text('$day $weekday',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isFriday ? FontWeight.bold : FontWeight.w500,
                                color: isFriday
                                    ? Colors.orange.shade700
                                    : theme.textTheme.bodyMedium?.color)),
                      ),
                      ..._members.map((m) {
                        final count = _mealCountOn(m.id, day);
                        return GestureDetector(
                          onTap: () => _showDayEntryDialog(day),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            child: count > 0
                                ? Container(
                              width: 32,
                              height: 28,
                              decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8)),
                              alignment: Alignment.center,
                              child: Text('$count',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary)),
                            )
                                : Text('–',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.withOpacity(0.4))),
                          ),
                        );
                      }),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.3)),
                  children: [
                    _cell('Total', isHeader: true, theme: theme),
                    ..._members.map((m) => _cell('${_totalForMember(m.id)}', isHeader: true, theme: theme)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, {bool isHeader = false, bool small = false, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(text,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: small ? 12 : 14,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              color: isHeader ? theme.colorScheme.primary : null)),
    );
  }

  void _showDayEntryDialog(int day) {
    final year = int.parse(widget.monthId.split('-')[0]);
    final month = int.parse(widget.monthId.split('-')[1]);
    setState(() {
      _date = DateTime(year, month, day);
      _showCalendar = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Switched to entry view for $day/$month/$year'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }
}

// ============================================================
// SECTION 13 — BAZAR SCREEN
// ============================================================

class BazarScreen extends StatefulWidget {
  final String monthId;
  final VoidCallback openDrawer;
  const BazarScreen({super.key, required this.monthId, required this.openDrawer});
  @override
  State<BazarScreen> createState() => _BazarScreenState();
}

class _BazarScreenState extends State<BazarScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _category = 'General';
  DateTime _date = DateTime.now();
  List<BazarEntry> _entries = [];
  double _total = 0;
  bool _showCalendar = false;

  static const _categories = [
    'General',
    'Rice',
    'Oil',
    'Fish/Meat',
    'Vegetables',
    'Spices',
    'Gas',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final entries = _db.getBazarByMonth(widget.monthId)..sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _entries = entries;
      _total = entries.fold(0.0, (s, e) => s + e.amount);
    });
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Enter a valid amount'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    _db.saveBazar(BazarEntry(
        amount: amount,
        note: _noteCtrl.text.trim(),
        category: _category,
        date: _date,
        monthId: widget.monthId));
    _amountCtrl.clear();
    _noteCtrl.clear();
    _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Bazar entry added!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  double _totalOnDay(int day) {
    final year = int.parse(widget.monthId.split('-')[0]);
    final month = int.parse(widget.monthId.split('-')[1]);
    return _entries
        .where((e) => e.date.year == year && e.date.month == month && e.date.day == day)
        .fold(0.0, (s, e) => s + e.amount);
  }

  List<BazarEntry> _entriesOnDay(int day) {
    final year = int.parse(widget.monthId.split('-')[0]);
    final month = int.parse(widget.monthId.split('-')[1]);
    return _entries
        .where((e) => e.date.year == year && e.date.month == month && e.date.day == day)
        .toList();
  }

  int _daysInMonth() {
    final year = int.parse(widget.monthId.split('-')[0]);
    final month = int.parse(widget.monthId.split('-')[1]);
    return DateTime(year, month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.openDrawer),
        title: const Text('Bazar & Expenses'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600)),
              icon: Icon(_showCalendar ? Icons.list_rounded : Icons.calendar_month_rounded, size: 20),
              label: Text(_showCalendar ? 'Entry' : 'Calendar'),
              onPressed: () => setState(() => _showCalendar = !_showCalendar),
            ),
          ),
        ],
      ),
      body: _showCalendar ? _buildCalendarView() : _buildEntryView(),
    );
  }

  Widget _buildEntryView() {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        color: theme.colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Bazar This Month',
                  style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('৳${_total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text('${_entries.length} Items',
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              leading: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
              title: Text('${_date.day} / ${_date.month} / ${_date.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: const Text('Tap to change date'),
              trailing: const Icon(Icons.edit_calendar_rounded),
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now());
                if (d != null) setState(() => _date = d);
              },
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
            const SizedBox(height: 8),
            TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Amount (৳)', prefixText: '৳ ')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              icon: const Icon(Icons.expand_more_rounded),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
              onChanged: (v) => setState(() => _category = v ?? 'General'),
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (e.g. Rice 5kg, Oil 2L)')),
            const SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: const Text('Add Bazar Entry'),
                    onPressed: _save)),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      if (_entries.isNotEmpty) ...[
        Text('RECENT ENTRIES',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ..._entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                radius: 22,
                child: Text(e.category.substring(0, 1),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
              ),
              title: Text(e.category, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${e.date.day}/${e.date.month}/${e.date.year}'
                    '${e.note.isNotEmpty ? "  ·  ${e.note}" : ""}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey)),
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('৳${e.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                    splashRadius: 20,
                    onPressed: () {
                      _db.deleteBazar(e.id);
                      _load();
                    }),
              ]),
            ),
          ),
        )),
      ] else
        Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                  child: Column(children: [
                    Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('No bazar entries yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Add your first bazar cost above',
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ])),
            )),
    ]);
  }

  Widget _buildCalendarView() {
    final theme = Theme.of(context);
    final days = _daysInMonth();
    final isDark = theme.brightness == Brightness.dark;
    final altRowBg = isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);
    final year = int.parse(widget.monthId.split('-')[0]);
    final month = int.parse(widget.monthId.split('-')[1]);

    return Column(children: [
      Container(
        width: double.infinity,
        color: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Monthly Total', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          Text('৳${_total.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ]),
      ),
      Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(16)
              ),
              clipBehavior: Clip.antiAlias,
              child: Table(
                border: TableBorder.symmetric(inside: BorderSide(color: borderColor)),
                columnWidths: const {
                  0: FixedColumnWidth(80),
                  1: FlexColumnWidth(1),
                  2: FixedColumnWidth(90)
                },
                children: [
                  TableRow(
                      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.3)),
                      children: [
                        _calCell('Date', isHeader: true, theme: theme),
                        _calCell('Items', isHeader: true, theme: theme),
                        _calCell('Amount', isHeader: true, theme: theme),
                      ]),
                  ...List.generate(days, (i) {
                    final day = i + 1;
                    final date = DateTime(year, month, day);
                    final weekday =
                    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
                    final isFriday = date.weekday == 5;
                    final dayEntries = _entriesOnDay(day);
                    final dayTotal = _totalOnDay(day);
                    final hasEntries = dayEntries.isNotEmpty;

                    if (!hasEntries) {
                      final rowBg = isFriday
                          ? Colors.orangeAccent.withOpacity(isDark ? 0.1 : 0.05)
                          : i.isOdd
                          ? altRowBg
                          : null;
                      return TableRow(
                        decoration: rowBg != null ? BoxDecoration(color: rowBg) : null,
                        children: [
                          Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Text('$day $weekday',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isFriday ? FontWeight.bold : FontWeight.w500,
                                      color: isFriday
                                          ? Colors.orange.shade700
                                          : theme.textTheme.bodySmall?.color))),
                          Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Text('—',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.withOpacity(0.4)))),
                          Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Text('—',
                                  style: TextStyle(fontSize: 13, color: Colors.grey.withOpacity(0.4)),
                                  textAlign: TextAlign.right)),
                        ],
                      );
                    }

                    return TableRow(
                      decoration: BoxDecoration(color: Colors.teal.withOpacity(isDark ? 0.15 : 0.05)),
                      children: [
                        GestureDetector(
                          onTap: () => setState(() {
                            _date = DateTime(year, month, day);
                            _showCalendar = false;
                          }),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              child: Text('$day $weekday',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isFriday
                                          ? Colors.orange.shade700
                                          : theme.textTheme.bodyMedium?.color))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: dayEntries
                                  .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                      '• ${e.category}${e.note.isNotEmpty ? ": ${e.note}" : ""}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis)))
                                  .toList()),
                        ),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Text('৳${dayTotal.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal),
                                textAlign: TextAlign.right)),
                      ],
                    );
                  }),
                  TableRow(
                      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.3)),
                      children: [
                        _calCell('Total', isHeader: true, theme: theme),
                        _calCell('${_entries.length} Entries', isHeader: true, theme: theme),
                        _calCell('৳${_total.toStringAsFixed(0)}', isHeader: true, theme: theme),
                      ]),
                ],
              ),
            ),
          )),
    ]);
  }

  Widget _calCell(String text, {bool isHeader = false, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 13,
              fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
              color: isHeader ? theme.colorScheme.primary : null)),
    );
  }
}

// ============================================================
// SECTION 14 — OTHER COST SCREEN
// ============================================================

class OtherCostScreen extends StatefulWidget {
  final String monthId;
  final VoidCallback openDrawer;
  const OtherCostScreen({super.key, required this.monthId, required this.openDrawer});
  @override
  State<OtherCostScreen> createState() => _OtherCostScreenState();
}

class _OtherCostScreenState extends State<OtherCostScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  List<Member> _members = [];
  int? _selectedMemberId;
  String _category = 'Rent';
  List<OtherCost> _entries = [];
  bool _showSummary = false;

  static const _categories = [
    'Rent',
    'Trash',
    'Wifi',
    'Gas',
    'Electricity',
    'Khala',
    'Other'
  ];

  static const _categoryIcons = {
    'Rent': Icons.home_rounded,
    'Trash': Icons.delete_rounded,
    'Wifi': Icons.wifi_rounded,
    'Gas': Icons.local_fire_department_rounded,
    'Electricity': Icons.bolt_rounded,
    'Khala': Icons.person_rounded,
    'Other': Icons.more_horiz_rounded,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final members = _db.getActiveMembers();
    final entries = _db.getCostsByMonth(widget.monthId)..sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _members = members;
      if (_selectedMemberId == null || !members.any((m) => m.id == _selectedMemberId)) {
        _selectedMemberId = members.isNotEmpty ? members.first.id : null;
      }
      _entries = entries;
    });
  }

  void _save() {
    final memberId = _selectedMemberId;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please select a member first'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    _db.saveCost(OtherCost(
        memberId: memberId,
        amount: amount,
        category: _category,
        note: _noteCtrl.text.trim(),
        monthId: widget.monthId));
    _amountCtrl.clear();
    _noteCtrl.clear();
    _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Cost added!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  // ── Summary helpers ──────────────────────────────────────
  double _categoryTotal(String cat) =>
      _entries.where((e) => e.category == cat).fold(0.0, (s, e) => s + e.amount);

  double _memberTotal(int memberId) =>
      _entries.where((e) => e.memberId == memberId).fold(0.0, (s, e) => s + e.amount);

  Map<int, double> _memberCategoryBreakdown(String cat) {
    final map = <int, double>{};
    for (final e in _entries.where((e) => e.category == cat)) {
      map[e.memberId] = (map[e.memberId] ?? 0) + e.amount;
    }
    return map;
  }

  double get _grandTotal => _entries.fold(0.0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.openDrawer),
        title: const Text('Other Costs'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600)),
              icon: Icon(_showSummary ? Icons.list_rounded : Icons.bar_chart_rounded, size: 20),
              label: Text(_showSummary ? 'Entry' : 'Summary'),
              onPressed: () => setState(() => _showSummary = !_showSummary),
            ),
          ),
        ],
      ),
      body: _showSummary ? _buildSummaryView() : _buildEntryView(),
    );
  }

  Widget _buildEntryView() {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            if (_members.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedMemberId,
                decoration: const InputDecoration(labelText: 'Assign to Member'),
                icon: const Icon(Icons.expand_more_rounded),
                items: _members
                    .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w500))))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMemberId = v),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              icon: const Icon(Icons.expand_more_rounded),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w500))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'Rent'),
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Amount (৳)', prefixText: '৳ ')),
            const SizedBox(height: 16),
            TextField(
                controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)')),
            const SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: _save, icon: const Icon(Icons.add_rounded), label: const Text('Add Cost'))),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      Text('RECENT ENTRIES',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ..._entries.map((e) {
        final member = _members.firstWhere((m) => m.id == e.memberId,
            orElse: () => Member(name: 'Unknown', initials: '?'));
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12)
                ),
                child: Icon(_categoryIcons[e.category] ?? Icons.receipt_rounded, color: theme.colorScheme.primary),
              ),
              title: Text('${member.name} · ${e.category}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${e.date.day}/${e.date.month} ${e.note.isNotEmpty ? '· ${e.note}' : ''}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('৳${e.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                    splashRadius: 20,
                    onPressed: () {
                      _db.deleteCost(e.id);
                      _load();
                    }),
              ]),
            ),
          ),
        );
      }),
      if (_entries.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(child: Text("No other costs recorded yet.", style: TextStyle(color: Colors.grey, fontSize: 15))),
        )
    ]);
  }

  Widget _buildSummaryView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        color: theme.colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Other Costs',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
            Text('৳${_grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      Text('BY MEMBER',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: _members.map((m) {
              final total = _memberTotal(m.id);
              final pct = _grandTotal > 0 ? total / _grandTotal : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(m.initials,
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(m.name,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                    Text('৳${total.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05)),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories
                        .where((cat) =>
                        _entries.any((e) => e.memberId == m.id && e.category == cat))
                        .map((cat) {
                      final amt = _entries
                          .where((e) => e.memberId == m.id && e.category == cat)
                          .fold(0.0, (s, e) => s + e.amount);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('$cat ৳${amt.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                      );
                    }).toList(),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('BY CATEGORY',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: _categories.map((cat) {
            final total = _categoryTotal(cat);
            if (total == 0) return const SizedBox.shrink();
            final breakdown = _memberCategoryBreakdown(cat);
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10)
                    ),
                    child: Icon(_categoryIcons[cat] ?? Icons.receipt_outlined,
                        size: 20, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(cat, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 4),
                        Wrap(
                            spacing: 8,
                            children: breakdown.entries.map((entry) {
                              final member = _members.firstWhere((m) => m.id == entry.key,
                                  orElse: () => Member(name: '?', initials: '?'));
                              return Text('${member.initials} ৳${entry.value.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500));
                            }).toList()),
                      ])),
                  Text('৳${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ]),
              ),
              if (cat != _categories.last && _categoryTotal(_categories[_categories.indexOf(cat)+1 < _categories.length ? _categories.indexOf(cat)+1 : _categories.length-1]) > 0)
                const Divider(height: 0, indent: 70),
            ]);
          }).toList(),
        ),
      ),
      const SizedBox(height: 32),
    ]);
  }
}

// ============================================================
// SECTION 15 — PAYMENT SCREEN
// ============================================================

class PaymentScreen extends StatefulWidget {
  final String monthId;
  final VoidCallback openDrawer;
  const PaymentScreen({super.key, required this.monthId, required this.openDrawer});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  List<Member> _members = [];
  int? _selectedMemberId;
  String _method = 'Cash';
  List<Payment> _entries = [];
  MonthSummary? _summary;
  bool _showSummary = false;

  static const _methods = ['Cash', 'bKash', 'Nagad', 'Bank', 'Other'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final members = _db.getActiveMembers();
    final entries = _db.getPaymentsByMonth(widget.monthId)..sort((a, b) => b.date.compareTo(a.date));
    final summary = computeSummary(widget.monthId);
    setState(() {
      _members = members;
      if (_selectedMemberId == null || !members.any((m) => m.id == _selectedMemberId)) {
        _selectedMemberId = members.isNotEmpty ? members.first.id : null;
      }
      _entries = entries;
      _summary = summary;
    });
  }

  String _dueLabel(int memberId) {
    final s = _summary;
    if (s == null) return '';
    final ms = s.members.firstWhere((m) => m.member.id == memberId,
        orElse: () => MemberSummary(
            member: Member(),
            totalMeals: 0,
            mealCost: 0,
            otherCosts: 0,
            totalCost: 0,
            paid: 0,
            due: 0));
    if (ms.hasDue) return '  —  owes ৳${ms.due.toStringAsFixed(0)}';
    if (ms.isOverpaid) return '  —  advance ৳${ms.due.abs().toStringAsFixed(0)}';
    return '  —  settled';
  }

  void _prefillDue() {
    final memberId = _selectedMemberId;
    if (memberId == null || _summary == null) return;
    final ms = _summary!.members.firstWhere((m) => m.member.id == memberId,
        orElse: () => MemberSummary(
            member: Member(),
            totalMeals: 0,
            mealCost: 0,
            otherCosts: 0,
            totalCost: 0,
            paid: 0,
            due: 0));
    if (ms.hasDue) _amountCtrl.text = ms.due.toStringAsFixed(0);
  }

  void _save() {
    final memberId = _selectedMemberId;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please select a member'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    _db.savePayment(Payment(
        memberId: memberId,
        amount: amount,
        method: _method,
        note: _noteCtrl.text.trim(),
        monthId: widget.monthId));
    _amountCtrl.clear();
    _noteCtrl.clear();
    _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Payment recorded!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  // ── Summary helpers ──────────────────────────────────────
  double _totalPaidByMember(int memberId) =>
      _entries.where((e) => e.memberId == memberId).fold(0.0, (s, e) => s + e.amount);

  double _totalPaidByMethod(String method) =>
      _entries.where((e) => e.method == method).fold(0.0, (s, e) => s + e.amount);

  double get _grandTotalPaid => _entries.fold(0.0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.openDrawer),
        title: const Text('Payments'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600)),
              icon: Icon(_showSummary ? Icons.list_rounded : Icons.pie_chart_rounded, size: 20),
              label: Text(_showSummary ? 'Entry' : 'Summary'),
              onPressed: () => setState(() => _showSummary = !_showSummary),
            ),
          ),
        ],
      ),
      body: _showSummary ? _buildSummaryView() : _buildEntryView(),
    );
  }

  Widget _buildEntryView() {
    final theme = Theme.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_summary != null && _summary!.members.isNotEmpty) ...[
        Text('CURRENT STATUS',
            style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ..._summary!.members.map((ms) {
          final color = ms.hasDue ? Colors.redAccent : ms.isOverpaid ? Colors.blueAccent : Colors.teal;
          final label = ms.hasDue
              ? 'Owes ৳${ms.due.toStringAsFixed(0)}'
              : ms.isOverpaid
              ? 'Advance ৳${ms.due.abs().toStringAsFixed(0)}'
              : 'Settled';
          final sub = 'Meals ৳${ms.mealCost.toStringAsFixed(0)}'
              ' + Costs ৳${ms.otherCosts.toStringAsFixed(0)}'
              ' − Paid ৳${ms.paid.toStringAsFixed(0)}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(ms.member.initials,
                        style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold))),
                title: Text(ms.member.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(label,
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                    if (ms.hasDue)
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedMemberId = ms.member.id);
                          _prefillDue();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('Tap to Pay',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
      Text('RECORD PAYMENT',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            if (_members.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedMemberId,
                decoration: const InputDecoration(labelText: 'Member'),
                icon: const Icon(Icons.expand_more_rounded),
                items: _members
                    .map((m) => DropdownMenuItem(
                    value: m.id, child: Text('${m.name}${_dueLabel(m.id)}', style: const TextStyle(fontWeight: FontWeight.w500))))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedMemberId = v);
                  _prefillDue();
                },
              ),
            const SizedBox(height: 16),
            TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Amount (৳)', prefixText: '৳ ')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              icon: const Icon(Icons.expand_more_rounded),
              items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.w500)))).toList(),
              onChanged: (v) => setState(() => _method = v ?? 'Cash'),
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Note (optional)')),
            const SizedBox(height: 24),
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                    onPressed: _save, icon: const Icon(Icons.done_rounded), label: const Text('Record Payment'))),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      Text('PAYMENT LOG', style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      if (_entries.isEmpty)
        Card(
            child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.payments_outlined, size: 40, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('No payments recorded yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    )))),
      ..._entries.map((e) {
        final member = _members.firstWhere((m) => m.id == e.memberId,
            orElse: () => Member(name: 'Unknown', initials: '?'));
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.teal.withOpacity(0.15),
                  child: Text(member.initials,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.teal, fontWeight: FontWeight.bold))),
              title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${e.method} · ${e.date.day}/${e.date.month}/${e.date.year}'
                      '${e.note.isNotEmpty ? " · ${e.note}" : ""}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('৳${e.amount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 16)),
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                    splashRadius: 20,
                    onPressed: () {
                      _db.deletePayment(e.id);
                      _load();
                    }),
              ]),
            ),
          ),
        );
      }),
    ]);
  }

  Widget _buildSummaryView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = _summary;

    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        color: theme.colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Collected', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text('৳${_grandTotalPaid.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ]),
            if (s != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                const Text('Still Outstanding', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text('৳${s.totalDue.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: s.totalDue > 0 ? Colors.red.shade200 : Colors.teal.shade200,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ]),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      Text('BY MEMBER',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: _members.map((m) {
              final paid = _totalPaidByMember(m.id);
              final ms = s?.members.firstWhere((ms) => ms.member.id == m.id,
                  orElse: () => MemberSummary(
                      member: m,
                      totalMeals: 0,
                      mealCost: 0,
                      otherCosts: 0,
                      totalCost: 0,
                      paid: 0,
                      due: 0));
              final due = ms?.due ?? 0;
              final statusColor = (ms?.hasDue ?? false)
                  ? Colors.redAccent
                  : (ms?.isOverpaid ?? false)
                  ? Colors.blueAccent
                  : Colors.teal;
              final statusLabel = (ms?.hasDue ?? false)
                  ? '৳${due.toStringAsFixed(0)} Due'
                  : (ms?.isOverpaid ?? false)
                  ? '+৳${due.abs().toStringAsFixed(0)} Adv'
                  : 'Settled ✓';

              final methodAmounts = <String, double>{};
              for (final e in _entries.where((e) => e.memberId == m.id)) {
                methodAmounts[e.method] = (methodAmounts[e.method] ?? 0) + e.amount;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(
                        radius: 18,
                        backgroundColor: statusColor.withOpacity(0.15),
                        child: Text(m.initials,
                            style: TextStyle(
                                fontSize: 12, color: statusColor, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          if (ms != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                  'Cost ৳${ms.totalCost.toStringAsFixed(0)} · Paid ৳${paid.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                            ),
                        ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(statusLabel,
                          style: TextStyle(
                              fontSize: 12, color: statusColor, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  if (methodAmounts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    if (ms != null && ms.totalCost > 0)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (paid / ms.totalCost).clamp(0.0, 1.0),
                          minHeight: 8,
                          color: statusColor,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: methodAmounts.entries
                            .map((entry) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(20)),
                          child: Text('${entry.key} ৳${entry.value.toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.tealAccent : Colors.teal.shade800, fontWeight: FontWeight.w600)),
                        ))
                            .toList()),
                  ],
                ]),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('BY METHOD',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: _methods.map((method) {
            final total = _totalPaidByMethod(method);
            if (total == 0) return const SizedBox.shrink();
            final count = _entries.where((e) => e.method == method).length;
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.account_balance_wallet_rounded, size: 22, color: Colors.teal)),
                  title: Text(method, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: Text('$count transaction${count > 1 ? "s" : ""}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                  trailing: Text('৳${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                if (method != _methods.last && _totalPaidByMethod(_methods[_methods.indexOf(method)+1 < _methods.length ? _methods.indexOf(method)+1 : _methods.length-1]) > 0)
                  const Divider(height: 1, indent: 80),
              ],
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 32),
    ]);
  }
}

// ============================================================
// SECTION 16 — HISTORY SCREEN
// ============================================================

class HistoryScreen extends StatefulWidget {
  final String currentMonthId;
  final VoidCallback openDrawer;
  const HistoryScreen({super.key, required this.currentMonthId, required this.openDrawer});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> _monthIds = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _monthIds = _db.getAllMonthIds());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.openDrawer),
        title: const Text('Monthly History'),
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _monthIds.isEmpty
          ? Center(
          child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.history_rounded, size: 48, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Text('No history yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Add meals and expenses to start building history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
              ])))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _monthIds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final id = _monthIds[i];
          final isCurrent = id == widget.currentMonthId;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: isCurrent ? theme.colorScheme.primaryContainer : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Icon(Icons.folder_rounded,
                      color: isCurrent ? theme.colorScheme.primary : Colors.grey),
                ),
                title: Text(_formatMonthId(id),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(isCurrent ? 'Current Active Month' : 'Archived Record', style: TextStyle(color: isCurrent ? theme.colorScheme.primary : Colors.grey, fontWeight: FontWeight.w500)),
                ),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      onPressed: () => _exportSvc.shareJson(id),
                      icon: const Icon(Icons.data_object_rounded, size: 22),
                      tooltip: 'Export JSON',
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  IconButton(
                      onPressed: () => _exportSvc.sharePdf(id),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
                      tooltip: 'Export PDF',
                      color: Colors.redAccent),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// SECTION 17 — SETTINGS SCREEN
// ============================================================

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeToggle;
  final VoidCallback openDrawer;
  const SettingsScreen(
      {super.key, required this.isDark, required this.onThemeToggle, required this.openDrawer});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Member> _members = [];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    setState(() => _members = _db.getActiveMembers());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.openDrawer),
        title: const Text('Settings'),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _sectionLabel('MEMBERS'),
        ..._members.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(m.initials, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary))),
              title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              subtitle: Text('Joined ${_formatMonthId(m.joinedMonthId)}', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    color: theme.colorScheme.primary,
                    onPressed: () => _showMemberDialog(member: m)),
                IconButton(
                    icon: const Icon(Icons.person_remove_rounded, size: 20, color: Colors.redAccent),
                    onPressed: () => _confirmSoftDelete(m)),
              ]),
            ),
          ),
        )),
        Card(
          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Icon(Icons.person_add_rounded, color: theme.colorScheme.primary),
            title: Text('Add New Member', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            onTap: () => _showMemberDialog(),
          ),
        ),
        const SizedBox(height: 24),
        _sectionLabel('APPEARANCE'),
        Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              secondary: Icon(widget.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
              value: widget.isDark,
              activeColor: theme.colorScheme.primary,
              onChanged: widget.onThemeToggle,
            )),
        const SizedBox(height: 24),
        _sectionLabel('DATA & EXPORT'),
        Card(
            child: Column(children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: const Icon(Icons.data_object_rounded),
                title: const Text('Export JSON Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Current month — importable later'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _exportSvc.shareJson(_currentMonthId()),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: const Icon(Icons.picture_as_pdf_rounded),
                title: const Text('Export PDF Report', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Current month — formatted summary'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _exportSvc.sharePdf(_currentMonthId()),
              ),
              const Divider(height: 1, indent: 60),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: const Icon(Icons.upload_file_rounded),
                title: const Text('Import from Backup', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Pick a .json MessManager file'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _runImport,
              ),
            ])),
        const SizedBox(height: 32),
        Center(
            child: Text('MessManager v1.0.0\nLocal-first • ObjectBox',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.withOpacity(0.6), height: 1.5))),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
    child: Text(label,
        style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700)),
  );

  void _showMemberDialog({Member? member}) {
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final initCtrl = TextEditingController(text: member?.initials ?? '');
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.colorScheme.surface,
        title: Text(member == null ? 'Add Member' : 'Edit Member', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
              autofocus: true,
              textCapitalization: TextCapitalization.words),
          const SizedBox(height: 16),
          TextField(
              controller: initCtrl,
              decoration: const InputDecoration(labelText: 'Initials (e.g. IM)'),
              maxLength: 2,
              textCapitalization: TextCapitalization.characters),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final init = initCtrl.text.trim().toUpperCase();
              if (name.isEmpty || init.isEmpty) return;
              final m = member ?? Member();
              m.name = name;
              m.initials = init;
              m.isActive = true;
              m.joinedMonthId = _currentMonthId();
              m.createdAt = DateTime.now();
              _db.saveMember(m);
              Navigator.pop(context);
              _loadMembers();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSoftDelete(Member m) async {
    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Remove Member?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('${m.name} will be hidden but all their history is preserved.'),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) {
      _db.softDeleteMember(m.id);
      _loadMembers();
    }
  }

  Future<void> _runImport() async {
    final result = await _importSvc.pickFile();
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }

    final theme = Theme.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Import Backup?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'This replaces all data for ${_formatMonthId(result.backup!.monthId)}.\n\nOther months are not affected.'),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Import')),
        ],
      ),
    );

    if (ok == true && result.backup != null) {
      _importSvc.commitImport(result.backup!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Import successful!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
        _loadMembers();
      }
    }
  }
}

// ============================================================
// SECTION 18 — SHARED WIDGET: STEPPER
// ============================================================

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24)
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: Icon(Icons.remove_rounded, color: value > 0 ? theme.colorScheme.primary : Colors.grey),
          splashRadius: 20,
        ), 
        SizedBox(
            width: 24,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: Icon(Icons.add_rounded, color: theme.colorScheme.primary),
          splashRadius: 20,
        ),
      ]),
    );
  }
}

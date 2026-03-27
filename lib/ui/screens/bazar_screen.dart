import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../data/services/db_service.dart';
import '../../data/models/bazar_entry.dart';

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
    'General', 'Rice', 'Oil', 'Fish/Meat', 'Vegetables', 'Spices', 'Gas', 'Other'
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
    final entries = dbService.getBazarByMonth(widget.monthId)
      ..sort((a, b) => b.date.compareTo(a.date));
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
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    dbService.saveBazar(BazarEntry(
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
    final isDark = theme.brightness == Brightness.dark;
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
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: Icon(
                _showCalendar ? Icons.list_rounded : Icons.calendar_month_rounded,
                size: 18,
              ),
              label: Text(_showCalendar ? 'Entry' : 'Calendar'),
              onPressed: () => setState(() => _showCalendar = !_showCalendar),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
          ),
        ),
      ),
      body: _showCalendar ? _buildCalendarView() : _buildEntryView(),
    );
  }

  Widget _buildEntryView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                : [const Color(0xFF059669), const Color(0xFF047857)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Total Bazar This Month',
              style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '৳${_total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_entries.length} Items',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now());
                if (d != null) setState(() => _date = d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF5F5F4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
                  ),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded,
                      color: theme.colorScheme.primary, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${_date.day} / ${_date.month} / ${_date.year}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  Icon(
                    Icons.edit_calendar_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(labelText: 'Amount (৳)', prefixText: '৳ '),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              icon: const Icon(Icons.expand_more_rounded, size: 20),
              items: _categories
                  .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'General'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Note (e.g. Rice 5kg, Oil 2L)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Bazar Entry'),
                onPressed: _save,
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 28),
      if (_entries.isNotEmpty) ...[
        Text(
          'RECENT ENTRIES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
          ),
        ),
        const SizedBox(height: 12),
        ..._entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      e.category.substring(0, 1),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.category,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      '${e.date.day}/${e.date.month}/${e.date.year}'
                          '${e.note.isNotEmpty ? "  ·  ${e.note}" : ""}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(
                  '৳${e.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: const Color(0xFFF87171),
                  splashRadius: 18,
                  onPressed: () {
                    dbService.deleteBazar(e.id);
                    _load();
                  },
                ),
              ]),
            ),
          ),
        )),
      ] else
        _buildBazarEmpty(),
    ]);
  }

  Widget _buildBazarEmpty() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Center(
          child: Column(children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 40,
              color: const Color(0xFFA8A29E).withOpacity(0.5),
            ),
            const SizedBox(height: 14),
            const Text('No bazar entries yet',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Add your first bazar cost above',
                style: TextStyle(fontSize: 13, color: Color(0xFFA8A29E))),
          ]),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    final theme = Theme.of(context);
    final days = _daysInMonth();
    final isDark = theme.brightness == Brightness.dark;
    final altRowBg = isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFFAFAF9);
    final borderColor = isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE7E5E4);
    final year = int.parse(widget.monthId.split('-')[0]);
    final month = int.parse(widget.monthId.split('-')[1]);

    return Column(children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF064E3B), const Color(0xFF065F46)]
                : [const Color(0xFF059669), const Color(0xFF047857)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text(
            'Monthly Total',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Text(
            '৳${_total.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              border: TableBorder.symmetric(inside: BorderSide(color: borderColor)),
              columnWidths: const {
                0: FixedColumnWidth(80),
                1: FlexColumnWidth(1),
                2: FixedColumnWidth(90),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.primaryContainer.withOpacity(0.25)
                        : theme.colorScheme.primaryContainer.withOpacity(0.4),
                  ),
                  children: [
                    _calCell('Date', isHeader: true, theme: theme),
                    _calCell('Items', isHeader: true, theme: theme),
                    _calCell('Amount', isHeader: true, theme: theme),
                  ],
                ),
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
                        ? (isDark
                        ? const Color(0xFFFBBF24).withOpacity(0.07)
                        : const Color(0xFFFEF3C7))
                        : i.isOdd
                        ? altRowBg
                        : null;
                    return TableRow(
                      decoration: rowBg != null ? BoxDecoration(color: rowBg) : null,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          child: Text(
                            '$day $weekday',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isFriday ? FontWeight.w700 : FontWeight.w500,
                              color: isFriday
                                  ? (isDark
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFFB45309))
                                  : theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          child: Text(
                            '—',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD6D3D1),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          child: Text(
                            '—',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFD6D3D1),
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }

                  return TableRow(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF059669).withOpacity(0.12)
                          : const Color(0xFFD1FAE5),
                    ),
                    children: [
                      GestureDetector(
                        onTap: () => setState(() {
                          _date = DateTime(year, month, day);
                          _showCalendar = false;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          child: Text(
                            '$day $weekday',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isFriday
                                  ? (isDark
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFFB45309))
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: dayEntries
                              .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '• ${e.category}${e.note.isNotEmpty ? ": ${e.note}" : ""}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                        child: Text(
                          '৳${dayTotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.primaryContainer.withOpacity(0.25)
                        : theme.colorScheme.primaryContainer.withOpacity(0.4),
                  ),
                  children: [
                    _calCell('Total', isHeader: true, theme: theme),
                    _calCell('${_entries.length} Entries', isHeader: true, theme: theme),
                    _calCell('৳${_total.toStringAsFixed(0)}', isHeader: true, theme: theme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _calCell(String text, {bool isHeader = false, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? theme.colorScheme.primary : null,
        ),
      ),
    );
  }
}
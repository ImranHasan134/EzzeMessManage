import 'package:flutter/material.dart';
import '../../data/services/db_service.dart';
import '../../data/models/member.dart';
import '../../data/models/meal_entry.dart';
import '../shell/main_shell.dart';

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
    final members = dbService.getActiveMembers();
    final all = dbService.getMealsByMonth(widget.monthId);
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
        dbService.saveMeal(
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
    final isDark = theme.brightness == Brightness.dark;

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
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline, size: 36, color: Color(0xFFA8A29E)),
            ),
            const SizedBox(height: 20),
            const Text('No members yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Go to Settings to add your first member.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFA8A29E), fontSize: 14)),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Go to Settings'),
              onPressed: () {
                final shell = context.findAncestorStateOfType<MainShellState>();
                shell?.setState(() => shell.index = 6);
              },
            ),
          ]),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [
      // Date selector
      Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2024),
                lastDate: DateTime.now());
            if (d != null) setState(() => _date = d);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.calendar_today_rounded,
                    color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${_date.day} / ${_date.month} / ${_date.year}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to change date',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF57534E) : const Color(0xFFC7C5C1),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 12),
      // Meal entry card
      Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(children: [
            // Header row
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                Expanded(
                  child: Text(
                    'MEMBER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Text(
                  'MEALS TODAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
                    letterSpacing: 0.6,
                  ),
                ),
              ]),
            ),
            Divider(
              height: 1,
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
            ),
            ...List.generate(_members.length, (i) {
              final m = _members[i];
              final count = _counts[m.id] ?? 0;
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: i < _members.length - 1
                        ? BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFEFEDEB),
                      width: 1,
                    )
                        : BorderSide.none,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        m.initials,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  // Stepper
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF5F5F4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFE7E5E4),
                      ),
                    ),
                    child: Row(children: [
                      _stepperBtn(
                        icon: Icons.remove_rounded,
                        enabled: count > 0,
                        onTap: count > 0
                            ? () => setState(() => _counts[m.id] = count - 1)
                            : null,
                        theme: theme,
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: count > 0
                                ? theme.colorScheme.primary
                                : (isDark ? const Color(0xFF44403C) : const Color(0xFFC7C5C1)),
                          ),
                        ),
                      ),
                      _stepperBtn(
                        icon: Icons.add_rounded,
                        enabled: true,
                        onTap: () => setState(() => _counts[m.id] = count + 1),
                        theme: theme,
                      ),
                    ]),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'Total Today',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$total meals',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ]),
              FilledButton.icon(
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('Save Meals'),
                onPressed: total > 0 ? _save : null,
              ),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 28),
      // Section header
      Text(
        'MONTHLY TOTALS',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: _members.map((m) {
              final tot = _totalForMember(m.id);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        m.initials,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tot > 0
                          ? theme.colorScheme.primaryContainer
                          : (isDark
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFF5F5F4)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$tot meals',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: tot > 0
                            ? theme.colorScheme.onPrimaryContainer
                            : (isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E)),
                      ),
                    ),
                  ),
                ]),
              );
            }).toList(),
          ),
        ),
      ),
    ]);
  }

  Widget _stepperBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? theme.colorScheme.primary
              : (theme.brightness == Brightness.dark
              ? const Color(0xFF3F3F46)
              : const Color(0xFFD6D3D1)),
        ),
      ),
    );
  }

  Widget _buildCalendarView(ThemeData theme) {
    final days = _daysInMonth();
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFE7E5E4);
    final altRowBg = isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFFAFAF9);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              border: TableBorder.symmetric(
                inside: BorderSide(color: borderColor, width: 1),
              ),
              defaultColumnWidth: const FixedColumnWidth(56),
              columnWidths: {
                0: const FixedColumnWidth(90),
                ..._members.asMap().map((i, _) => MapEntry(i + 1, const FixedColumnWidth(64))),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                        : theme.colorScheme.primaryContainer.withOpacity(0.4),
                  ),
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
                  final weekday =
                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
                  final isFriday = date.weekday == 5;
                  final rowBg = isFriday
                      ? (isDark
                      ? const Color(0xFFFBBF24).withOpacity(0.08)
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
                                : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      ..._members.map((m) {
                        final count = _mealCountOn(m.id, day);
                        return GestureDetector(
                          onTap: () => _showDayEntryDialog(day),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            child: count > 0
                                ? Container(
                              width: 30,
                              height: 26,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            )
                                : Text(
                              '–',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xFF3F3F46)
                                    : const Color(0xFFD6D3D1),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
                TableRow(
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                        : theme.colorScheme.primaryContainer.withOpacity(0.4),
                  ),
                  children: [
                    _cell('Total', isHeader: true, theme: theme),
                    ..._members.map((m) =>
                        _cell('${_totalForMember(m.id)}', isHeader: true, theme: theme)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(String text,
      {bool isHeader = false, bool small = false, required ThemeData theme}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: small ? 11 : 13,
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          color: isHeader
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
        ),
      ),
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
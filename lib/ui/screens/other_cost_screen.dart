import 'package:flutter/material.dart';
import '../../data/services/db_service.dart';
import '../../data/models/member.dart';
import '../../data/models/other_cost.dart';

class OtherCostScreen extends StatefulWidget {
  final String monthId;
  final VoidCallback openDrawer;
  const OtherCostScreen({super.key, required this.monthId, required this.openDrawer});
  @override
  State<OtherCostScreen> createState() => _OtherCostScreenState();
}

class _OtherCostScreenState extends State<OtherCostScreen> {
  final _noteCtrl = TextEditingController();
  final Map<String, TextEditingController> _amountCtrls = {};
  List<Member> _members = [];
  int? _selectedMemberId;
  List<OtherCost> _entries = [];
  bool _showSummary = false;

  static const _categories = [
    'Rent', 'Trash', 'Wifi', 'Gas', 'Electricity', 'Khala', 'Other'
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
    for (final cat in _categories) {
      _amountCtrls[cat] = TextEditingController();
    }
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedMemberId == null && _members.isNotEmpty) {
        setState(() => _selectedMemberId = _members.first.id);
      }
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    for (final ctrl in _amountCtrls.values) ctrl.dispose();
    super.dispose();
  }

  void _load() {
    final members = dbService.getActiveMembers();
    final entries = dbService.getCostsByMonth(widget.monthId)
      ..sort((a, b) => b.date.compareTo(a.date));
    setState(() {
      _members = members;
      if (members.isNotEmpty &&
          (_selectedMemberId == null ||
              !members.any((m) => m.id == _selectedMemberId))) {
        _selectedMemberId = members.first.id;
      }
      _entries = entries;
    });
  }

  void _save() {
    final memberId = _selectedMemberId ?? (_members.isNotEmpty ? _members.first.id : null);
    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('No members found. Add members in Settings.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }

    int saved = 0;
    for (final cat in _categories) {
      final amount = double.tryParse(_amountCtrls[cat]!.text.trim());
      if (amount != null && amount > 0) {
        dbService.saveCost(OtherCost(
            memberId: memberId,
            amount: amount,
            category: cat,
            note: _noteCtrl.text.trim(),
            monthId: widget.monthId));
        saved++;
      }
    }

    if (saved == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Enter at least one amount'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }

    for (final ctrl in _amountCtrls.values) ctrl.clear();
    _noteCtrl.clear();
    _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$saved cost${saved > 1 ? "s" : ""} added!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

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
    final isDark = theme.brightness == Brightness.dark;
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
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: Icon(
                _showSummary ? Icons.list_rounded : Icons.bar_chart_rounded,
                size: 18,
              ),
              label: Text(_showSummary ? 'Entry' : 'Summary'),
              onPressed: () => setState(() => _showSummary = !_showSummary),
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
      body: _showSummary ? _buildSummaryView() : _buildEntryView(),
    );
  }

  Widget _buildEntryView() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            if (_members.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedMemberId,
                decoration: const InputDecoration(labelText: 'Assign to Member'),
                icon: const Icon(Icons.expand_more_rounded, size: 20),
                items: _members
                    .map((m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(m.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14)),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedMemberId = v),
              ),
            const SizedBox(height: 18),
            ...List.generate(_categories.length, (i) {
              final cat = _categories[i];
              final icon = _categoryIcons[cat] ?? Icons.receipt_rounded;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon,
                        color: theme.colorScheme.onPrimaryContainer, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _amountCtrls[cat],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: '0',
                        prefixText: '৳ ',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                      ),
                    ),
                  ),
                ]),
              );
            }),
            const SizedBox(height: 4),
            Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFFE7E5E4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                  labelText: 'Note (applies to all entries above)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add Costs'),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 28),
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
      ..._entries.map((e) {
        final member = _members.firstWhere((m) => m.id == e.memberId,
            orElse: () => Member(name: 'Unknown', initials: '?'));
        return Padding(
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
                  child: Icon(
                    _categoryIcons[e.category] ?? Icons.receipt_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${member.name} · ${e.category}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 3),
                        Text(
                          '${e.date.day}/${e.date.month}'
                              '${e.note.isNotEmpty ? " · ${e.note}" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF78716C)
                                : const Color(0xFFA8A29E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]),
                ),
                const SizedBox(width: 8),
                Text('৳${e.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: const Color(0xFFF87171),
                  splashRadius: 18,
                  onPressed: () {
                    dbService.deleteCost(e.id);
                    _load();
                  },
                ),
              ]),
            ),
          ),
        );
      }),
      if (_entries.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Center(
            child: Text(
              'No other costs recorded yet.',
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF78716C)
                    : const Color(0xFFA8A29E),
                fontSize: 14,
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildSummaryView() {
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
          const Text(
            'Total Other Costs',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            '৳${_grandTotal.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ]),
      ),
      const SizedBox(height: 24),
      Text(
        'BY MEMBER',
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
          padding: const EdgeInsets.all(18),
          child: Column(
            children: _members.map((m) {
              final total = _memberTotal(m.id);
              final pct = _grandTotal > 0 ? total / _grandTotal : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Center(
                        child: Text(
                          m.initials,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(m.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                    Text(
                      '৳${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      color: theme.colorScheme.primary,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFE7E5E4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _categories
                        .where((cat) =>
                        _entries.any((e) => e.memberId == m.id && e.category == cat))
                        .map((cat) {
                      final amt = _entries
                          .where((e) => e.memberId == m.id && e.category == cat)
                          .fold(0.0, (s, e) => s + e.amount);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$cat ৳${amt.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
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
      Text(
        'BY CATEGORY',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(
          children: _categories.map((cat) {
            final total = _categoryTotal(cat);
            if (total == 0) return const SizedBox.shrink();
            final breakdown = _memberCategoryBreakdown(cat);
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _categoryIcons[cat] ?? Icons.receipt_outlined,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(cat,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        children: breakdown.entries.map((entry) {
                          final member = _members.firstWhere((m) => m.id == entry.key,
                              orElse: () => Member(name: '?', initials: '?'));
                          return Text(
                            '${member.initials} ৳${entry.value.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF78716C)
                                  : const Color(0xFFA8A29E),
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList(),
                      ),
                    ]),
                  ),
                  Text(
                    '৳${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ]),
              ),
              if (cat != _categories.last &&
                  _categoryTotal(_categories[_categories.indexOf(cat) + 1 < _categories.length
                      ? _categories.indexOf(cat) + 1
                      : _categories.length - 1]) >
                      0)
                Divider(
                  height: 0,
                  indent: 70,
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
                ),
            ]);
          }).toList(),
        ),
      ),
      const SizedBox(height: 32),
    ]);
  }
}
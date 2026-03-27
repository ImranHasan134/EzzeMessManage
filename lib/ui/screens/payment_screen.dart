import 'package:flutter/material.dart';
import '../../core/calculation_engine.dart';
import '../../data/services/db_service.dart';
import '../../data/models/member.dart';
import '../../data/models/payment.dart';

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
    final members = dbService.getActiveMembers();
    final entries = dbService.getPaymentsByMonth(widget.monthId)
      ..sort((a, b) => b.date.compareTo(a.date));
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
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Please enter a valid amount'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    dbService.savePayment(Payment(
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

  double _totalPaidByMember(int memberId) =>
      _entries.where((e) => e.memberId == memberId).fold(0.0, (s, e) => s + e.amount);

  double _totalPaidByMethod(String method) =>
      _entries.where((e) => e.method == method).fold(0.0, (s, e) => s + e.amount);

  double get _grandTotalPaid => _entries.fold(0.0, (s, e) => s + e.amount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: Icon(
                _showSummary ? Icons.list_rounded : Icons.pie_chart_rounded,
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
      if (_summary != null && _summary!.members.isNotEmpty) ...[
        Text(
          'CURRENT STATUS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
          ),
        ),
        const SizedBox(height: 12),
        ..._summary!.members.map((ms) {
          final Color statusColor;
          final String statusLabel;
          if (ms.hasDue) {
            statusColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
            statusLabel = 'Owes ৳${ms.due.toStringAsFixed(0)}';
          } else if (ms.isOverpaid) {
            statusColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
            statusLabel = 'Advance ৳${ms.due.abs().toStringAsFixed(0)}';
          } else {
            statusColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
            statusLabel = 'Settled';
          }
          final sub = 'Meals ৳${ms.mealCost.toStringAsFixed(0)}'
              ' + Costs ৳${ms.otherCosts.toStringAsFixed(0)}'
              ' − Paid ৳${ms.paid.toStringAsFixed(0)}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        ms.member.initials,
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(ms.member.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(sub,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
                          )),
                    ]),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          )),
                      if (ms.hasDue)
                        GestureDetector(
                          onTap: () {
                            setState(() => _selectedMemberId = ms.member.id);
                            _prefillDue();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Pay Now',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
      Text(
        'RECORD PAYMENT',
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
          child: Column(children: [
            if (_members.isNotEmpty)
              DropdownButtonFormField<int>(
                value: _selectedMemberId,
                decoration: const InputDecoration(labelText: 'Member'),
                icon: const Icon(Icons.expand_more_rounded, size: 20),
                items: _members
                    .map((m) => DropdownMenuItem(
                  value: m.id,
                  child: Text(
                    '${m.name}${_dueLabel(m.id)}',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedMemberId = v);
                  _prefillDue();
                },
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(labelText: 'Amount (৳)', prefixText: '৳ '),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              icon: const Icon(Icons.expand_more_rounded, size: 20),
              items: _methods
                  .map((m) => DropdownMenuItem(
                value: m,
                child: Text(m,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _method = v ?? 'Cash'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.done_rounded, size: 18),
                label: const Text('Record Payment'),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 28),
      Text(
        'PAYMENT LOG',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
        ),
      ),
      const SizedBox(height: 12),
      if (_entries.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(children: [
                Icon(
                  Icons.payments_outlined,
                  size: 36,
                  color: const Color(0xFFA8A29E).withOpacity(0.5),
                ),
                const SizedBox(height: 12),
                const Text('No payments recorded yet.',
                    style: TextStyle(
                      color: Color(0xFFA8A29E),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    )),
              ]),
            ),
          ),
        ),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF059669).withOpacity(0.15)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      member.initials,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(member.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      '${e.method} · ${e.date.day}/${e.date.month}/${e.date.year}'
                          '${e.note.isNotEmpty ? " · ${e.note}" : ""}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]),
                ),
                Text(
                  '৳${e.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: const Color(0xFFF87171),
                  splashRadius: 18,
                  onPressed: () {
                    dbService.deletePayment(e.id);
                    _load();
                  },
                ),
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
            const Text('Total Collected',
                style: TextStyle(
                    color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(
              '৳${_grandTotalPaid.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ]),
          if (s != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Outstanding',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(
                '৳${s.totalDue.toStringAsFixed(0)}',
                style: TextStyle(
                  color: s.totalDue > 0
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFF6EE7B7),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ]),
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
              final Color statusColor;
              final String statusLabel;
              if (ms?.hasDue ?? false) {
                statusColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
                statusLabel = '৳${due.toStringAsFixed(0)} Due';
              } else if (ms?.isOverpaid ?? false) {
                statusColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
                statusLabel = '+৳${due.abs().toStringAsFixed(0)} Adv';
              } else {
                statusColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
                statusLabel = 'Settled ✓';
              }

              final methodAmounts = <String, double>{};
              for (final e in _entries.where((e) => e.memberId == m.id)) {
                methodAmounts[e.method] = (methodAmounts[e.method] ?? 0) + e.amount;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          m.initials,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(m.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        if (ms != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Cost ৳${ms.totalCost.toStringAsFixed(0)} · Paid ৳${paid.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
                  if (methodAmounts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    if (ms != null && ms.totalCost > 0)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (paid / ms.totalCost).clamp(0.0, 1.0),
                          minHeight: 6,
                          color: statusColor,
                          backgroundColor: isDark
                              ? Colors.white.withOpacity(0.05)
                              : const Color(0xFFE7E5E4),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: methodAmounts.entries
                          .map((entry) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF059669).withOpacity(0.15)
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${entry.key} ৳${entry.value.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF065F46),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ))
                          .toList(),
                    ),
                  ],
                ]),
              );
            }).toList(),
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'BY METHOD',
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
          children: _methods.map((method) {
            final total = _totalPaidByMethod(method);
            if (total == 0) return const SizedBox.shrink();
            final count = _entries.where((e) => e.method == method).length;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF059669).withOpacity(0.15)
                          : const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 20,
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(method,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        '$count transaction${count > 1 ? "s" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ]),
                  ),
                  Text(
                    '৳${total.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ]),
              ),
              if (method != _methods.last &&
                  _totalPaidByMethod(_methods[_methods.indexOf(method) + 1 < _methods.length
                      ? _methods.indexOf(method) + 1
                      : _methods.length - 1]) >
                      0)
                Divider(
                  height: 0,
                  indent: 72,
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
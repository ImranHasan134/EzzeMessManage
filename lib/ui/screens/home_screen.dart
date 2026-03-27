import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../core/calculation_engine.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: widget.openDrawer,
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dashboard'),
          Text(
            formatMonthId(widget.monthId), // Updated to public method
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
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
      body: _loading
          ? Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
          strokeWidth: 2,
        ),
      )
          : RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async => _load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            if (_summary != null) ...[
              _buildSummaryCards(_summary!),
              const SizedBox(height: 28),
              _buildSectionHeader(
                context,
                'MEMBERS',
                trailing: _buildPill(
                  '${_summary!.members.length} Active',
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                  theme,
                ),
              ),
              const SizedBox(height: 12),
              ..._summary!.members.map(_buildMemberCard),
              if (_summary!.members.isEmpty) _buildEmptyState(
                icon: Icons.people_outline,
                title: 'No members yet',
                subtitle: 'Go to Settings to add your first member.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label, {Widget? trailing}) {
    return Row(children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF57534E)
              : const Color(0xFFA8A29E),
        ),
      ),
      const Spacer(),
      if (trailing != null) trailing,
    ]);
  }

  Widget _buildPill(String text, Color textColor, Color bgColor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: const Color(0xFFA8A29E)),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFA8A29E), fontSize: 13),
          ),
        ]),
      ),
    );
  }

  Widget _buildSummaryCards(MonthSummary s) {
    final remaining = s.bazarRemaining;
    final remainingColor = remaining >= 0
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);
    final remainingBg = remaining >= 0
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEE2E2);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(children: [
      Row(children: [
        Expanded(
          child: _metricCard(
            'Meal Rate',
            '৳${s.mealRate.toStringAsFixed(2)}',
            'Per meal',
            Icons.restaurant_menu_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            'Total Meals',
            '${s.totalMeals}',
            'This month',
            Icons.tag_rounded,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: _metricCard(
            'Bazar Spent',
            '৳${s.totalBazar.toStringAsFixed(0)}',
            widget.monthId,
            Icons.shopping_basket_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            'Budget',
            '৳${s.bazarBudget.toStringAsFixed(0)}',
            'Paid − Fixed',
            Icons.account_balance_wallet_rounded,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      // Highlight card for remaining
      Container(
        decoration: BoxDecoration(
          color: isDark
              ? remainingColor.withOpacity(0.12)
              : remainingBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? remainingColor.withOpacity(0.25)
                : remainingColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: remainingColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.analytics_rounded, size: 20, color: remainingColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bazar Remaining',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: remainingColor.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remaining >= 0 ? 'Surplus in the pool' : 'Pool is overspent',
                    style: TextStyle(
                      fontSize: 11,
                      color: remainingColor.withOpacity(0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '৳${remaining.abs().toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: remainingColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _metricCard(String label, String value, String sub, IconData icon,
      {Color? color, bool full = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = color ?? theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: full ? 26 : 20,
                fontWeight: FontWeight.w800,
                color: cardColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(MemberSummary ms) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color statusColor;
    final String statusLabel;
    final String badgeText;

    if (ms.hasDue) {
      statusColor = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      statusLabel = '৳${ms.due.toStringAsFixed(0)} Due';
      badgeText = 'Owes';
    } else if (ms.isOverpaid) {
      statusColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
      statusLabel = '+৳${ms.due.abs().toStringAsFixed(0)}';
      badgeText = 'Overpaid';
    } else {
      statusColor = isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      statusLabel = 'Settled';
      badgeText = 'Clear';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showMemberDetail(ms),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      ms.member.initials,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + meals
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ms.member.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${ms.totalMeals} meals',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.3,
                        ),
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
    final isDark = theme.brightness == Brightness.dark;
    final Color statusColor = ms.hasDue
        ? (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626))
        : ms.isOverpaid
        ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB))
        : (isDark ? const Color(0xFF34D399) : const Color(0xFF059669));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE7E5E4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  ms.member.initials,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ms.member.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3),
            ),
            const SizedBox(height: 22),
            // Detail rows container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF5F5F4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
                ),
              ),
              child: Column(
                children: [
                  _detailRow('Meal Cost (${ms.totalMeals})', '৳${ms.mealCost.toStringAsFixed(0)}'),
                  Divider(
                    height: 20,
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
                  ),
                  _detailRow('Other Costs', '৳${ms.otherCosts.toStringAsFixed(0)}'),
                  Divider(
                    height: 20,
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
                  ),
                  _detailRow('Total Cost', '৳${ms.totalCost.toStringAsFixed(0)}', bold: true),
                  Divider(
                    height: 20,
                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
                  ),
                  _detailRow('Total Paid', '৳${ms.paid.toStringAsFixed(0)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Status highlight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withOpacity(0.25),
                ),
              ),
              child: _detailRow(
                ms.hasDue ? 'Final Due' : ms.isOverpaid ? 'Advance Paid' : 'Status',
                ms.hasDue || ms.isOverpaid ? '৳${ms.due.abs().toStringAsFixed(0)}' : '✓ Settled',
                bold: true,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(
        label,
        style: TextStyle(
          color: color ?? (isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E)),
          fontSize: 14,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: color ?? (isDark ? const Color(0xFFF5F5F4) : const Color(0xFF1C1917)),
          fontSize: 14,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    ]);
  }
}
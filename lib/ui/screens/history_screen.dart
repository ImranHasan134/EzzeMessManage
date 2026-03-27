import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../data/services/db_service.dart';
import '../../data/services/export_service.dart';

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
    setState(() => _monthIds = dbService.getAllMonthIds());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.openDrawer),
        title: const Text('Monthly History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
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
      body: _monthIds.isEmpty
          ? Center(
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
              child: const Icon(Icons.history_rounded, size: 36, color: Color(0xFFA8A29E)),
            ),
            const SizedBox(height: 20),
            const Text('No history yet',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Add meals and expenses to start building history.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFFA8A29E), fontSize: 14),
            ),
          ]),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        itemCount: _monthIds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final id = _monthIds[i];
          final isCurrent = id == widget.currentMonthId;
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? theme.colorScheme.primaryContainer
                        : (isDark
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFFF5F5F4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCurrent ? Icons.folder_open_rounded : Icons.folder_rounded,
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : (isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      formatMonthId(id),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isCurrent ? 'Current Active Month' : 'Archived Record',
                      style: TextStyle(
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : (isDark
                            ? const Color(0xFF78716C)
                            : const Color(0xFFA8A29E)),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ]),
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _iconActionBtn(
                    icon: Icons.data_object_rounded,
                    color: theme.colorScheme.primary,
                    tooltip: 'Export JSON',
                    onTap: () => exportService.shareJson(id),
                  ),
                  const SizedBox(width: 4),
                  _iconActionBtn(
                    icon: Icons.picture_as_pdf_rounded,
                    color: const Color(0xFFDC2626),
                    tooltip: 'Export PDF',
                    onTap: () => exportService.sharePdf(id),
                  ),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _iconActionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
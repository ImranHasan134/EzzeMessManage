import 'package:flutter/material.dart';
import '../../core/helpers.dart';
import '../../data/services/db_service.dart';
import '../../data/models/member.dart';
import '../../data/services/export_service.dart';
import '../../data/services/import_service.dart';

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
    setState(() => _members = dbService.getActiveMembers());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.openDrawer),
        title: const Text('Settings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 32), children: [
        _sectionLabel('MEMBERS', context),
        const SizedBox(height: 10),
        ..._members.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Center(
                    child: Text(
                      m.initials,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      'Joined ${formatMonthId(m.joinedMonthId)}',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ]),
                ),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _smallIconBtn(
                    icon: Icons.edit_rounded,
                    color: theme.colorScheme.primary,
                    onTap: () => _showMemberDialog(member: m),
                  ),
                  const SizedBox(width: 4),
                  _smallIconBtn(
                    icon: Icons.person_remove_rounded,
                    color: const Color(0xFFF87171),
                    onTap: () => _confirmSoftDelete(m),
                  ),
                ]),
              ]),
            ),
          ),
        )),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showMemberDialog(),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                  : theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_add_rounded,
                    color: theme.colorScheme.primary, size: 16),
              ),
              const SizedBox(width: 14),
              Text(
                'Add New Member',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 28),
        _sectionLabel('APPEARANCE', context),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFF5F5F4),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  widget.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 18,
                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                ),
              ),
              title: const Text('Dark Mode',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text(
                widget.isDark ? 'Currently dark' : 'Currently light',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
                ),
              ),
              value: widget.isDark,
              activeColor: const Color(0xFF059669),
              onChanged: widget.onThemeToggle,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _sectionLabel('DATA & EXPORT', context),
        const SizedBox(height: 10),
        Card(
          child: Column(children: [
            _settingsTile(
              icon: Icons.data_object_rounded,
              iconColor: const Color(0xFF059669),
              title: 'Export JSON Backup',
              subtitle: 'Current month — importable later',
              onTap: () => exportService.shareJson(currentMonthId()),
              isDark: isDark,
            ),
            Divider(
              height: 0,
              indent: 66,
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
            ),
            _settingsTile(
              icon: Icons.picture_as_pdf_rounded,
              iconColor: const Color(0xFFDC2626),
              title: 'Export PDF Report',
              subtitle: 'Current month — formatted summary',
              onTap: () => exportService.sharePdf(currentMonthId()),
              isDark: isDark,
            ),
            Divider(
              height: 0,
              indent: 66,
              color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4),
            ),
            _settingsTile(
              icon: Icons.upload_file_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'Import from Backup',
              subtitle: 'Pick a .json MessManager file',
              onTap: _runImport,
              isDark: isDark,
            ),
          ]),
        ),
        const SizedBox(height: 36),
        Center(
          child: Column(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'MessManager v1.0.0',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFF78716C) : const Color(0xFF92928A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Local-first · ObjectBox',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF44403C) : const Color(0xFFC7C5C1),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: isDark ? const Color(0xFF44403C) : const Color(0xFFC7C5C1),
      ),
      onTap: onTap,
    );
  }

  Widget _smallIconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _sectionLabel(String label, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E),
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  void _showMemberDialog({Member? member}) {
    final nameCtrl = TextEditingController(text: member?.name ?? '');
    final initCtrl = TextEditingController(text: member?.initials ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          member == null ? 'Add Member' : 'Edit Member',
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name'),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: initCtrl,
            decoration: const InputDecoration(labelText: 'Initials (e.g. IM)'),
            maxLength: 2,
            textCapitalization: TextCapitalization.characters,
          ),
        ]),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final init = initCtrl.text.trim().toUpperCase();
              if (name.isEmpty || init.isEmpty) return;
              final m = member ?? Member();
              m.name = name;
              m.initials = init;
              m.isActive = true;
              m.joinedMonthId = currentMonthId();
              m.createdAt = DateTime.now();
              dbService.saveMember(m);
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member?'),
        content: Text('${m.name} will be hidden but all their history is preserved.'),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      dbService.softDeleteMember(m.id);
      _loadMembers();
    }
  }

  Future<void> _runImport() async {
    final result = await importService.pickFile();
    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.message),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import Backup?'),
        content: Text(
            'This replaces all data for ${formatMonthId(result.backup!.monthId)}.\n\nOther months are not affected.'),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (ok == true && result.backup != null) {
      importService.commitImport(result.backup!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Import successful!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
        _loadMembers();
      }
    }
  }
}
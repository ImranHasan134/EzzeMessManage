import 'package:flutter/material.dart';

import '../../core/helpers.dart';
import '../screens/home_screen.dart';
import '../screens/meal_screen.dart';
import '../screens/bazar_screen.dart';
import '../screens/other_cost_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';

class MainShell extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onThemeToggle;
  const MainShell({super.key, required this.isDark, required this.onThemeToggle});

  @override
  State<MainShell> createState() => MainShellState();
}

// Keeping state public so SettingsScreen can navigate via findAncestorStateOfType
class MainShellState extends State<MainShell> {
  int index = 0;
  final String _monthId = currentMonthId();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildScreen() {
    final od = openDrawer;
    switch (index) {
      case 0: return HomeScreen(monthId: _monthId, openDrawer: od);
      case 1: return MealScreen(monthId: _monthId, openDrawer: od);
      case 2: return BazarScreen(monthId: _monthId, openDrawer: od);
      case 3: return OtherCostScreen(monthId: _monthId, openDrawer: od);
      case 4: return PaymentScreen(monthId: _monthId, openDrawer: od);
      case 5: return HistoryScreen(currentMonthId: _monthId, openDrawer: od);
      case 6: return SettingsScreen(isDark: widget.isDark, onThemeToggle: widget.onThemeToggle, openDrawer: od);
      default: return HomeScreen(monthId: _monthId, openDrawer: od);
    }
  }

  void _navigate(int i) {
    setState(() => index = i);
    Navigator.pop(context);
  }

  void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  Widget _drawerTile(String label, IconData icon, int navIndex) {
    final selected = index == navIndex;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: selected ? theme.colorScheme.primary : (isDark ? const Color(0xFF78716C) : const Color(0xFF92928A)),
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? theme.colorScheme.primary : (isDark ? const Color(0xFFD6D3D1) : const Color(0xFF44403C)),
          ),
        ),
        selected: selected,
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.07),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => _navigate(navIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel = formatMonthId(_monthId);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        width: 272,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 28,
                left: 20, right: 20, bottom: 20,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 14),
                  Text('MessManager', style: TextStyle(color: isDark ? const Color(0xFFF5F5F4) : const Color(0xFF1C1917), fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 3),
                  Text(monthLabel, style: TextStyle(color: isDark ? const Color(0xFF78716C) : const Color(0xFFA8A29E), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  children: [
                    _drawerTile('Other Costs', Icons.receipt_long_rounded, 3),
                    _drawerTile('Payments', Icons.payments_rounded, 4),
                    _drawerTile('History', Icons.history_rounded, 5),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4), height: 1),
                    ),
                    _drawerTile('Settings', Icons.settings_rounded, 6),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('v1.0.0 · Local-first', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF57534E) : const Color(0xFFA8A29E))),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _buildScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE7E5E4), width: 1))),
        child: NavigationBar(
          selectedIndex: index.clamp(0, 2),
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant_rounded), label: 'Meals'),
            NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), selectedIcon: Icon(Icons.shopping_bag_rounded), label: 'Bazar'),
          ],
        ),
      ),
    );
  }
}
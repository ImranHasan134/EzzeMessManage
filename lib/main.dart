import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/services/db_service.dart';
import 'core/theme.dart';
import 'ui/shell/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dbService.init(); // From part 1
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
      theme: AppTheme.buildTheme(Brightness.light),
      darkTheme: AppTheme.buildTheme(Brightness.dark),
      home: MainShell(isDark: _isDark, onThemeToggle: _toggleTheme),
    );
  }
}
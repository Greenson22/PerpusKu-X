// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/pages/dashboard_page.dart';
import 'presentation/providers/directory_provider.dart';
import 'presentation/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? savedPath = prefs.getString('root_directory_path');

  runApp(
    ProviderScope(
      overrides: [
        rootDirectoryProvider.overrideWith((ref) {
          return savedPath;
        }),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tonton (watch) themeProvider untuk mendapatkan state ThemeMode saat ini
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PerpusKu',
      // Atur tema terang
      theme: AppTheme.getLightTheme(),
      // Atur tema gelap
      darkTheme: AppTheme.getDarkTheme(),
      // Gunakan themeMode dari provider untuk menentukan tema mana yang aktif
      themeMode: themeMode,
      home: const DashboardPage(),
    );
  }
}

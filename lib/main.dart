// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        // 👇 INI BAGIAN YANG DIPERBAIKI 👇
        rootDirectoryProvider.overrideWith((ref) {
          return savedPath;
        }),
        // 👆 ----------------------- 👆
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PerpusKu',
      theme: AppTheme.getTheme(),
      home: const DashboardPage(),
    );
  }
}

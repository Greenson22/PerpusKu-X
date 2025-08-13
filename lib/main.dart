// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pages/dashboard_page.dart'; // UBAH import ini
import 'presentation/themes/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PerpusKu', // Ganti judul aplikasi
      theme: AppTheme.getTheme(),
      home: const DashboardPage(), // UBAH halaman utama
    );
  }
}

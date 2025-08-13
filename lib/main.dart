// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:webview_flutter/webview_flutter.dart'; // Import webview -> DIHAPUS
import 'presentation/pages/topics_page.dart';
import 'presentation/themes/app_theme.dart';

void main() {
  // Pastikan binding siap sebelum menjalankan aplikasi
  WidgetsFlutterBinding.ensureInitialized();

  // ProviderScope adalah widget yang menyimpan state dari semua provider.
  // Harus berada di paling atas dari widget tree aplikasi.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PerpusKu Topics',
      // Menggunakan tema yang sudah kita definisikan secara terpisah.
      theme: AppTheme.getTheme(),
      // Halaman awal aplikasi.
      home: const TopicsPage(),
    );
  }
}

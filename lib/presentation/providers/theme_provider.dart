// lib/presentation/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kunci untuk menyimpan preferensi tema di SharedPreferences
const String _themePrefsKey = 'app_theme_mode';

/// Provider yang akan mengelola state dari ThemeMode aplikasi.
///
/// State ini akan secara otomatis diinisialisasi dari SharedPreferences
/// saat aplikasi pertama kali dijalankan.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  // Selama inisialisasi, kita tidak bisa mengakses SharedPreferences secara sinkron.
  // Oleh karena itu, kita akan memuatnya secara asinkron dan memperbarui state setelahnya.
  // Untuk sementara, kita berikan nilai default (misalnya, ThemeMode.light).
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Mulai dengan tema terang sebagai default sementara
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  /// Memuat tema yang tersimpan dari SharedPreferences.
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeName = prefs.getString(_themePrefsKey);

    if (themeModeName == ThemeMode.dark.name) {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light; // Default ke terang jika tidak ada atau korup
    }
  }

  /// Mengubah tema dan menyimpannya ke SharedPreferences.
  Future<void> toggleTheme() async {
    // Tentukan tema baru berdasarkan state saat ini
    final newTheme = state == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    // Simpan preferensi baru
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefsKey, newTheme.name);

    // Perbarui state untuk merefleksikan perubahan di UI
    state = newTheme;
  }
}

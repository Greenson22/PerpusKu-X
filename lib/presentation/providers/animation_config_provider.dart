// lib/presentation/providers/animation_config_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kunci untuk menyimpan seluruh konfigurasi dalam satu string JSON
const String _animationConfigPrefsKey = 'animation_config';

/// Model data untuk menampung semua konfigurasi animasi.
class AnimationConfig {
  final double speed; // Pengali kecepatan (misal: 1.0)
  final int count; // Jumlah tulisan (misal: 20)
  final double size; // Ukuran font (misal: 16.0)

  AnimationConfig({
    required this.speed,
    required this.count,
    required this.size,
  });

  // Nilai default untuk konfigurasi awal.
  factory AnimationConfig.defaults() {
    return AnimationConfig(speed: 1.0, count: 20, size: 16.0);
  }

  // Membuat salinan objek dengan nilai yang diubah.
  AnimationConfig copyWith({double? speed, int? count, double? size}) {
    return AnimationConfig(
      speed: speed ?? this.speed,
      count: count ?? this.count,
      size: size ?? this.size,
    );
  }

  // Konversi dari Map (untuk JSON).
  factory AnimationConfig.fromMap(Map<String, dynamic> map) {
    return AnimationConfig(
      speed: map['speed'] as double,
      count: map['count'] as int,
      size: map['size'] as double,
    );
  }

  // Konversi ke Map (untuk JSON).
  Map<String, dynamic> toMap() {
    return {'speed': speed, 'count': count, 'size': size};
  }
}

/// Provider yang mengelola state dari seluruh konfigurasi animasi.
final animationConfigProvider =
    StateNotifierProvider<AnimationConfigNotifier, AnimationConfig>((ref) {
      return AnimationConfigNotifier();
    });

class AnimationConfigNotifier extends StateNotifier<AnimationConfig> {
  AnimationConfigNotifier() : super(AnimationConfig.defaults()) {
    _loadConfig();
  }

  /// Memuat konfigurasi yang tersimpan dari SharedPreferences.
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final String? configString = prefs.getString(_animationConfigPrefsKey);

    if (configString != null) {
      try {
        final configMap = json.decode(configString) as Map<String, dynamic>;
        state = AnimationConfig.fromMap(configMap);
      } catch (e) {
        // Jika data korup, gunakan nilai default.
        state = AnimationConfig.defaults();
      }
    }
  }

  /// Memperbarui state dan menyimpannya ke SharedPreferences.
  Future<void> updateConfig(AnimationConfig newConfig) async {
    final prefs = await SharedPreferences.getInstance();
    final String configString = json.encode(newConfig.toMap());
    await prefs.setString(_animationConfigPrefsKey, configString);
    state = newConfig;
  }
}

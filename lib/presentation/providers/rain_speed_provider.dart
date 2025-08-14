// lib/presentation/providers/rain_speed_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kunci untuk menyimpan preferensi kecepatan di SharedPreferences
const String _rainSpeedPrefsKey = 'rain_animation_speed';

/// Provider yang mengelola state kecepatan animasi hujan matriks.
///
/// Nilai state adalah double yang berfungsi sebagai pengali kecepatan.
/// 1.0 = Normal, 0.5 = Lambat, 2.0 = Cepat.
final rainSpeedProvider = StateNotifierProvider<RainSpeedNotifier, double>((
  ref,
) {
  return RainSpeedNotifier();
});

class RainSpeedNotifier extends StateNotifier<double> {
  // Nilai default kecepatan adalah 1.0 (normal)
  RainSpeedNotifier() : super(1.0) {
    _loadSpeed();
  }

  /// Memuat kecepatan yang tersimpan dari SharedPreferences.
  Future<void> _loadSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    // Jika tidak ada data tersimpan, gunakan nilai default 1.0
    state = prefs.getDouble(_rainSpeedPrefsKey) ?? 1.0;
  }

  /// Mengubah kecepatan dan menyimpannya ke SharedPreferences.
  Future<void> setSpeed(double newSpeed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rainSpeedPrefsKey, newSpeed);
    // Perbarui state untuk merefleksikan perubahan di UI secara real-time
    state = newSpeed;
  }
}

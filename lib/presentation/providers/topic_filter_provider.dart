// lib/presentation/providers/topic_filter_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Kunci untuk menyimpan preferensi di SharedPreferences
const String _topicFilterPrefsKey = 'rain_topic_filter';
// Kunci khusus untuk menandakan pilihan "Semua Topik"
const String allTopicsKey = 'ALL_TOPICS';

/// Provider yang mengelola daftar topik yang dipilih untuk animasi.
final topicFilterProvider =
    StateNotifierProvider<TopicFilterNotifier, List<String>>((ref) {
      return TopicFilterNotifier();
    });

class TopicFilterNotifier extends StateNotifier<List<String>> {
  // Secara default, semua topik akan dipilih.
  TopicFilterNotifier() : super([allTopicsKey]) {
    _loadFilter();
  }

  /// Memuat filter yang tersimpan dari SharedPreferences.
  Future<void> _loadFilter() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_topicFilterPrefsKey) ?? [allTopicsKey];
  }

  /// Menyimpan filter saat ini ke SharedPreferences.
  Future<void> _saveFilter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_topicFilterPrefsKey, state);
  }

  /// Menambah atau menghapus topik dari filter.
  void toggleTopic(String topicName) {
    if (state.contains(allTopicsKey)) {
      // Jika "Semua Topik" aktif, memulai pilihan baru akan menonaktifkannya.
      state = [topicName];
    } else if (state.contains(topicName)) {
      // Jika topik sudah ada, hapus dari daftar.
      state = state.where((t) => t != topicName).toList();
      // Jika tidak ada topik yang tersisa, kembali ke default "Semua Topik".
      if (state.isEmpty) {
        state = [allTopicsKey];
      }
    } else {
      // Jika tidak, tambahkan topik ke daftar.
      state = [...state, topicName];
    }
    _saveFilter();
  }

  /// Mengatur filter untuk memilih semua topik.
  void selectAllTopics() {
    state = [allTopicsKey];
    _saveFilter();
  }
}

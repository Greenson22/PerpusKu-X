// presentation/pages/topics_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/topic_provider.dart';

/// Halaman UI yang menampilkan daftar topics.
/// Menggunakan `ConsumerWidget` dari Riverpod agar dapat "mendengarkan"
/// perubahan state dari provider.
class TopicsPage extends ConsumerWidget {
  const TopicsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // "Watch" provider untuk mendapatkan state terbaru (AsyncValue).
    // Widget ini akan otomatis rebuild saat state berubah (loading -> data/error).
    final topicsAsyncValue = ref.watch(topicsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('📚 Topics - Layer-First')),
      // `when` adalah cara elegan untuk menangani 3 state dari FutureProvider.
      body: topicsAsyncValue.when(
        // State 1: Data sedang dimuat
        loading: () => const Center(child: CircularProgressIndicator()),

        // State 2: Terjadi error saat memuat data
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),

        // State 3: Data berhasil dimuat
        data: (topics) {
          if (topics.isEmpty) {
            return const Center(child: Text('Tidak ada topic yang ditemukan.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    Icons.folder_open,
                    color: Colors.purple.shade300,
                  ),
                  title: Text(topic.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

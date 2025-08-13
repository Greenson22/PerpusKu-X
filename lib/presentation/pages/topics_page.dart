// presentation/pages/topics_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/presentation/pages/subjects_page.dart';
import '../providers/directory_provider.dart'; // IMPORT provider direktori
import '../providers/topic_provider.dart';

class TopicsPage extends ConsumerWidget {
  const TopicsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsyncValue = ref.watch(topicsProvider);
    // BACA path root untuk digunakan saat navigasi
    final rootPath = ref.watch(rootDirectoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('📚 Topics')), // Judul disesuaikan
      body: topicsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
        data: (topics) {
          // Tambahkan pengecekan jika rootPath belum di-set
          if (rootPath == null || rootPath.isEmpty) {
            return const Center(
              child: Text(
                'Folder utama belum dipilih.\nKembali ke Dashboard untuk memilih.',
                textAlign: TextAlign.center,
              ),
            );
          }
          if (topics.isEmpty) {
            return const Center(
              child: Text('Tidak ada topic yang ditemukan di folder ini.'),
            );
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
                  onTap: () {
                    // Pastikan rootPath tidak null sebelum navigasi
                    if (rootPath != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectsPage(
                            topicName: topic.name,
                            // MODIFIKASI: Gunakan path dinamis
                            topicPath: '$rootPath/${topic.name}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

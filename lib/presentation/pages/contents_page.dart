// lib/presentation/pages/contents_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/content_provider.dart';

class ContentsPage extends ConsumerWidget {
  final String subjectName;
  final String subjectPath;

  const ContentsPage({
    super.key,
    required this.subjectName,
    required this.subjectPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsyncValue = ref.watch(contentsProvider(subjectPath));

    return Scaffold(
      appBar: AppBar(title: Text(subjectName)),
      body: contentsAsyncValue.when(
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
        data: (contents) {
          if (contents.isEmpty) {
            return const Center(
              child: Text('Tidak ada konten HTML yang ditemukan.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: contents.length,
            itemBuilder: (context, index) {
              final content = contents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.code, color: Colors.blueGrey.shade300),
                  title: Text(content.name.replaceAll('.html', '')),
                  // onTap: () {
                  //   // TODO: Navigasi ke halaman untuk menampilkan konten HTML
                  // },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

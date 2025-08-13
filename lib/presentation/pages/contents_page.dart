// lib/presentation/pages/contents_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/content_provider.dart';
import 'content_view_page.dart';

// 1. Ubah menjadi ConsumerStatefulWidget untuk mengelola state lokal (search controller)
class ContentsPage extends ConsumerStatefulWidget {
  final String subjectName;
  final String subjectPath;

  const ContentsPage({
    super.key,
    required this.subjectName,
    required this.subjectPath,
  });

  @override
  ConsumerState<ContentsPage> createState() => _ContentsPageState();
}

class _ContentsPageState extends ConsumerState<ContentsPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dengarkan provider untuk mendapatkan data dan state pencarian
    final contentsAsyncValue = ref.watch(contentsProvider(widget.subjectPath));
    final searchQuery = ref.watch(contentSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: Column(
        children: [
          // 2. Tambahkan widget untuk search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari berdasarkan judul...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(contentSearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                // 3. Perbarui state provider saat pengguna mengetik
                ref.read(contentSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          // 4. Gunakan Expanded agar ListView mengambil sisa ruang
          Expanded(
            child: contentsAsyncValue.when(
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
                    child: Text(
                      'Tidak ada konten yang cocok dengan pencarian.',
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  itemCount: contents.length,
                  itemBuilder: (context, index) {
                    final content = contents[index];
                    final contentTitle = content.title;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.code,
                          color: Colors.blueGrey.shade300,
                        ),
                        title: Text(contentTitle),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContentViewPage(
                                contentPath: content.path,
                                contentName: contentTitle,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

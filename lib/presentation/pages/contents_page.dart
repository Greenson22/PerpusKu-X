// lib/presentation/pages/contents_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/content_provider.dart';
import 'content_view_page.dart';

// Pastikan class ini adalah ConsumerStatefulWidget
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

  // Fungsi untuk menampilkan dialog tambah konten
  void _showAddContentDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buat Konten Baru'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Judul Konten',
              hintText: 'Contoh: Pengenalan Dasar HTML',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Simpan'),
              onPressed: () async {
                final title = titleController.text;
                if (title.isNotEmpty) {
                  try {
                    // Panggil provider untuk membuat konten
                    await ref
                        .read(contentMutationProvider)
                        .createContent(widget.subjectPath, title);

                    if (mounted) {
                      Navigator.of(context).pop(); // Tutup dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Konten baru berhasil dibuat!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop(); // Tutup dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal membuat konten: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentsAsyncValue = ref.watch(contentsProvider(widget.subjectPath));
    final searchQuery = ref.watch(contentSearchQueryProvider);

    // Widget Scaffold adalah kerangka utama halaman
    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),

      // ======================================================
      // INI ADALAH TOMBOL TAMBAH YANG SEHARUSNYA MUNCUL
      // Pastikan kode ini berada di dalam Scaffold
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContentDialog, // Memanggil dialog saat ditekan
        tooltip: 'Tambah Konten',
        child: const Icon(Icons.add),
      ),

      // ======================================================
      body: Column(
        children: [
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
                ref.read(contentSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: contentsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (contents) {
                if (contents.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada konten yang cocok.'),
                  );
                }
                // Tambahkan padding di bagian bawah ListView agar tidak tertutup FAB
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                  itemCount: contents.length,
                  itemBuilder: (context, index) {
                    final content = contents[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.code,
                          color: Colors.blueGrey.shade300,
                        ),
                        title: Text(content.title),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContentViewPage(
                                contentPath: content.path,
                                contentName: content.title,
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

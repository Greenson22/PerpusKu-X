// lib/presentation/pages/contents_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/data/models/content_model.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart'; // IMPORT share_plus
import '../providers/content_provider.dart';

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
  bool _isProcessing = false; // State untuk loading indicator

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                    await ref
                        .read(contentMutationProvider)
                        .createContent(widget.subjectPath, title);

                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Konten baru berhasil dibuat!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop();
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

  /// Fungsi untuk membuka konten yang sudah digabung dalam format HTML.
  Future<void> _openContent(Content content) async {
    setState(() => _isProcessing = true);

    try {
      final mergedFilePath = await ref
          .read(contentServiceProvider)
          .createMergedHtmlFile(content.path);

      final result = await OpenFile.open(mergedFilePath);

      if (result.type != ResultType.done) {
        throw Exception(result.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  /// Membagikan file HTML agar bisa dibuka atau diedit di aplikasi lain.
  Future<void> _openInExternalApp(Content content) async {
    try {
      final xfile = XFile(content.path);
      await Share.shareXFiles(
        [xfile],
        subject: 'Edit Konten: ${content.title}',
        text: 'Pilih aplikasi untuk mengedit file ${content.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka file di aplikasi lain: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentsAsyncValue = ref.watch(contentsProvider(widget.subjectPath));
    final searchQuery = ref.watch(contentSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddContentDialog,
        tooltip: 'Tambah Konten',
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          Column(
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
                              ref
                                      .read(contentSearchQueryProvider.notifier)
                                      .state =
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (contents) {
                    if (contents.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada konten yang ditemukan.'),
                      );
                    }
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
                            // Panggil _openContent untuk melihat pratinjau
                            onTap: () => _openContent(content),
                            // Tombol untuk membuka di aplikasi eksternal
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_new),
                              tooltip: 'Buka / Edit di aplikasi lain',
                              onPressed: () => _openInExternalApp(content),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Tampilkan loading indicator di tengah layar jika sedang memproses
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Mempersiapkan file...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

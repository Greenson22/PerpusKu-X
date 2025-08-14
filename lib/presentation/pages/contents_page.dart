// lib/presentation/pages/contents_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/data/models/content_model.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
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
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddContentDialog() {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buat Konten Baru'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Konten',
                hintText: 'Contoh: Pengenalan State Management',
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul konten tidak boleh kosong';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text('Simpan'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final title = titleController.text;
                  try {
                    await ref
                        .read(contentMutationProvider)
                        .createContent(widget.subjectPath, title);
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Konten berhasil dibuat!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Mempersiapkan dan membuka file HTML gabungan di aplikasi eksternal (browser).
  Future<void> _viewContent(Content content) async {
    setState(() => _isProcessing = true);
    try {
      final contentMutation = ref.read(contentMutationProvider);
      final mergedFilePath = await contentMutation.contentService
          .createMergedHtmlFile(content.path);

      final result = await OpenFile.open(mergedFilePath);

      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka file: ${result.message}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mempersiapkan file untuk dilihat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Membuka file HTML untuk diedit di aplikasi eksternal.
  /// - Di Linux, akan mencoba membuka dengan text editor (gedit).
  /// - Di platform lain, akan menggunakan dialog "Bagikan/Buka Dengan".
  Future<void> _openInExternalApp(Content content) async {
    try {
      if (Platform.isLinux) {
        // Di Linux, coba buka dengan text editor 'gedit'
        final result = await Process.run('gedit', [content.path]);

        // Periksa jika ada error (misal: gedit tidak terinstall)
        if (result.exitCode != 0) {
          // Jika gedit gagal, coba buka dengan cara default (mungkin browser atau editor lain)
          final fallbackResult = await OpenFile.open(content.path);
          if (fallbackResult.type != ResultType.done) {
            throw Exception(
              'Gedit tidak ditemukan dan gagal membuka dengan aplikasi default. Pesan: ${fallbackResult.message}',
            );
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Gedit tidak ditemukan, file dibuka dengan aplikasi default.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      } else {
        // Untuk mobile (Android/iOS), gunakan dialog "Share"
        final xfile = XFile(content.path);
        await Share.shareXFiles(
          [xfile],
          subject: 'Edit Konten: ${content.title}',
          text: 'Pilih aplikasi untuk mengedit file ${content.name}',
        );
      }
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
                            subtitle: Text(
                              content.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'view') {
                                  _viewContent(content);
                                } else if (value == 'edit') {
                                  _openInExternalApp(content);
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'view',
                                      child: ListTile(
                                        leading: Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        title: Text('Lihat File'),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit_outlined),
                                        title: Text(
                                          'Edit di aplikasi eksternal',
                                        ),
                                      ),
                                    ),
                                  ],
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

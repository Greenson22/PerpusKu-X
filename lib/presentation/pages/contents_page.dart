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

  Future<void> _openInExternalApp(Content content) async {
    try {
      await _shareFileForEditing(
        filePath: content.path,
        subjectTitle: 'Edit Konten: ${content.title}',
        textMessage: 'Pilih aplikasi untuk mengedit file ${content.name}',
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

  Future<void> _editIndexHtml() async {
    final indexPath = '${widget.subjectPath}/index.html';
    try {
      await _shareFileForEditing(
        filePath: indexPath,
        subjectTitle: 'Edit Template Induk',
        textMessage: 'Pilih aplikasi untuk mengedit file index.html',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka index.html: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareFileForEditing({
    required String filePath,
    required String subjectTitle,
    required String textMessage,
  }) async {
    if (Platform.isLinux) {
      final result = await Process.run('gedit', [filePath]);
      if (result.exitCode != 0) {
        final fallbackResult = await OpenFile.open(filePath);
        if (fallbackResult.type != ResultType.done) {
          throw Exception(
            'Gedit tidak ditemukan dan gagal membuka dengan aplikasi default. Pesan: ${fallbackResult.message}',
          );
        } else if (mounted) {
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
    } else {
      final xfile = XFile(filePath);
      await Share.shareXFiles(
        [xfile],
        subject: subjectTitle,
        text: textMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentsAsyncValue = ref.watch(contentsProvider(widget.subjectPath));
    final searchQuery = ref.watch(contentSearchQueryProvider);

    return Scaffold(
      // --- BAGIAN YANG DIPERBAIKI ---
      appBar: AppBar(
        title: Text(widget.subjectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            tooltip: 'Edit Template Induk (index.html)',
            onPressed: _editIndexHtml,
          ),
        ],
      ),
      // Tombol FAB kembali seperti semula
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContentDialog,
        tooltip: 'Tambah Konten',
        icon: const Icon(Icons.add),
        label: const Text('Buat Konten'),
      ),
      // --- AKHIR BAGIAN YANG DIPERBAIKI ---
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan judul...',
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
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
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
                      return _EmptyState(
                        icon: Icons.html_outlined,
                        message: searchQuery.isNotEmpty
                            ? 'Tidak ada konten yang cocok dengan pencarian Anda.'
                            : 'Belum ada konten di sini.\nSilakan buat konten baru.',
                      );
                    }
                    return ListView.builder(
                      // Padding bawah disesuaikan kembali
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                      itemCount: contents.length,
                      itemBuilder: (context, index) {
                        final content = contents[index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Icon(
                              Icons.code,
                              color: Colors.blueGrey.shade400,
                              size: 36,
                            ),
                            title: Text(
                              content.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                        title: Text('Edit di aplikasi lain'),
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

// Widget kustom untuk tampilan state kosong
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/presentation/pages/contents_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:my_perpusku/data/models/content_model.dart';
import 'package:my_perpusku/data/models/content_stats_model.dart';
import 'package:my_perpusku/presentation/pages/image_gallery_page.dart';
import 'package:open_file/open_file.dart';
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

  void _showRenameContentDialog(Content content) {
    final titleController = TextEditingController(text: content.title);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ubah Judul Konten'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul Baru'),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul tidak boleh kosong';
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
                  final newTitle = titleController.text;
                  try {
                    await ref
                        .read(contentMutationProvider)
                        .renameContentTitle(content.path, newTitle);
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Judul berhasil diubah!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Gagal mengubah judul: $e'),
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
      final mergedFilePath = await ref
          .read(contentMutationProvider)
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

  Future<void> _openFileForEditing(String filePath) async {
    try {
      if (Platform.isLinux) {
        final result = await Process.run('gedit', [filePath]);
        if (result.exitCode != 0) {
          throw Exception(
            'Gagal membuka dengan gedit. Error: ${result.stderr}',
          );
        }
      } else {
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal membuka file: Tidak ada aplikasi yang cocok ditemukan. (${result.message})',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka file di editor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- KARTU INFORMASI YANG DISEMPURNAKAN ---
  Widget _buildInfoCard(ContentStats stats) {
    final theme = Theme.of(context);
    final String totalSizeFormatted = NumberFormat.compact().format(
      stats.totalContentSize,
    );

    String lastModifiedFormatted = 'N/A';
    if (stats.indexLastModified != null) {
      lastModifiedFormatted = DateFormat(
        'd MMM yyyy, HH:mm',
      ).format(stats.indexLastModified!);
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                'Informasi Subjek',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Divider(height: 1),
            _InfoRow(
              icon: Icons.article_outlined,
              label: 'Jumlah Konten',
              value: '${stats.contentCount} file ($totalSizeFormatted)',
            ),
            _InfoRow(
              icon: Icons.photo_library_outlined,
              label: 'Galeri',
              value:
                  '${stats.galleryStats.imageCount} gambar, ${stats.galleryStats.folderCount} folder',
            ),
            _InfoRow(
              icon: Icons.code_outlined,
              label: 'Template Diubah',
              value: lastModifiedFormatted,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentsAsyncValue = ref.watch(contentsProvider(widget.subjectPath));
    final statsAsyncValue = ref.watch(contentStatsProvider(widget.subjectPath));
    final searchQuery = ref.watch(contentSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Buka Galeri Gambar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageGalleryPage(
                    subjectName: widget.subjectName,
                    subjectPath: widget.subjectPath,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_outlined),
            tooltip: 'Edit Template Induk (index.html)',
            onPressed: () {
              final indexPath = '${widget.subjectPath}/index.html';
              _openFileForEditing(indexPath);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContentDialog,
        tooltip: 'Tambah Konten',
        icon: const Icon(Icons.add),
        label: const Text('Buat Konten'),
      ),
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
                    return Column(
                      children: [
                        statsAsyncValue.when(
                          data: (stats) => _buildInfoCard(stats),
                          loading: () => const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, s) => Card(
                            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            color: Colors.red.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('Gagal memuat info: $e'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
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
                                      } else if (value == 'edit_title') {
                                        _showRenameContentDialog(content);
                                      } else if (value == 'edit_file') {
                                        _openFileForEditing(content.path);
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
                                              title: Text('Lihat Konten'),
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'edit_title',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.title_outlined,
                                              ),
                                              title: Text('Ubah Judul'),
                                            ),
                                          ),
                                          const PopupMenuItem<String>(
                                            value: 'edit_file',
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.edit_outlined,
                                              ),
                                              title: Text('Edit File HTML'),
                                            ),
                                          ),
                                        ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

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

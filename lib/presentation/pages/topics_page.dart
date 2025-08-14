// presentation/pages/topics_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/presentation/pages/subjects_page.dart';
// --- PERUBAHAN DI SINI: IMPORT WIDGET DAN PROVIDER YANG DIBUTUHKAN ---
import '../providers/all_content_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/matrix_rain.dart';
// --- AKHIR PERUBAHAN ---
import '../providers/directory_provider.dart';
import '../providers/topic_provider.dart';

class TopicsPage extends ConsumerWidget {
  const TopicsPage({super.key});

  // Dialog untuk menambah/mengubah nama topic (tidak ada perubahan)
  void _showTopicDialog(
    BuildContext context,
    WidgetRef ref, {
    String? oldTopicPath,
    String? oldTopicName,
  }) {
    final isEditing = oldTopicPath != null;
    final titleController = TextEditingController(text: oldTopicName ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Ubah Nama Topic' : 'Buat Topic Baru'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Topic',
                hintText: 'Contoh: Pemrograman Flutter',
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama topic tidak boleh kosong';
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
                  final topicName = titleController.text;

                  try {
                    final mutation = ref.read(topicMutationProvider);
                    if (isEditing) {
                      await mutation.renameTopic(oldTopicPath!, topicName);
                    } else {
                      await mutation.createTopic(topicName);
                    }
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Topic berhasil ${isEditing ? 'diubah' : 'dibuat'}!',
                        ),
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

  // Dialog konfirmasi penghapusan (tidak ada perubahan)
  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    String topicPath,
    String topicName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Topic'),
          content: Text(
            'Apakah Anda yakin ingin menghapus topic "$topicName"?\nSemua subject dan konten di dalamnya juga akan terhapus.',
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref.read(topicMutationProvider).deleteTopic(topicPath);
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Topic berhasil dihapus.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsyncValue = ref.watch(topicsProvider);
    final rootPath = ref.watch(rootDirectoryProvider);
    // --- PERUBAHAN DI SINI: AMBIL STATE TEMA DAN DATA JUDUL ---
    final themeMode = ref.watch(themeProvider);
    final allTitlesAsync = ref.watch(allContentTitlesProvider);
    // --- AKHIR PERUBAHAN ---

    return Scaffold(
      appBar: AppBar(title: const Text('📚 Topics')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTopicDialog(context, ref),
        tooltip: 'Tambah Topic',
        icon: const Icon(Icons.add),
        label: const Text('Buat Topic'),
      ),
      // --- PERUBAHAN DI SINI: GUNAKAN STACK UNTUK LATAR BELAKANG ---
      body: Stack(
        children: [
          // 1. Lapisan Latar Belakang (Animasi)
          if (themeMode == ThemeMode.dark)
            Positioned.fill(
              child: allTitlesAsync.when(
                data: (titles) => MatrixRain(words: titles),
                loading: () => const MatrixRain(words: []),
                error: (err, stack) => const MatrixRain(words: []),
              ),
            ),

          // 2. Lapisan Konten Utama
          topicsAsyncValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: $error', textAlign: TextAlign.center),
              ),
            ),
            data: (topics) {
              if (rootPath == null || rootPath.isEmpty) {
                return const _EmptyState(
                  icon: Icons.folder_off_outlined,
                  message:
                      'Folder utama belum dipilih.\nKembali ke Dashboard untuk memilih.',
                );
              }
              if (topics.isEmpty) {
                return const _EmptyState(
                  icon: Icons.topic_outlined,
                  message: 'Belum ada topic.\nSilakan buat topic baru.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  final topicPath = '$rootPath/${topic.name}';
                  // --- PERUBAHAN DI SINI: BUAT KARTU MENJADI TRANSPARAN DI MODE GELAP ---
                  return Card(
                    color: themeMode == ThemeMode.dark
                        ? Theme.of(context).cardColor.withOpacity(0.6)
                        : Theme.of(context).cardColor,
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    // --- AKHIR PERUBAHAN ---
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      leading: const Icon(
                        Icons.folder_open,
                        size: 40,
                        color: Colors.purple,
                      ),
                      title: Text(
                        topic.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectsPage(
                              topicName: topic.name,
                              topicPath: topicPath,
                            ),
                          ),
                        );
                      },
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => Wrap(
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.edit_outlined),
                                title: const Text('Ubah Nama'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _showTopicDialog(
                                    context,
                                    ref,
                                    oldTopicPath: topicPath,
                                    oldTopicName: topic.name,
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _showDeleteConfirmationDialog(
                                    context,
                                    ref,
                                    topicPath,
                                    topic.name,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      // --- AKHIR PERUBAHAN ---
    );
  }
}

// Widget kustom untuk tampilan state kosong (tidak ada perubahan)
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

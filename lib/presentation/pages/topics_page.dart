// presentation/pages/topics_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/presentation/pages/subjects_page.dart';
import '../providers/directory_provider.dart';
import '../providers/topic_provider.dart';

class TopicsPage extends ConsumerWidget {
  const TopicsPage({super.key});

  // Dialog untuk menambah/mengubah nama topic
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

  // Dialog konfirmasi penghapusan
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

    return Scaffold(
      appBar: AppBar(title: const Text('📚 Topics')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTopicDialog(context, ref),
        tooltip: 'Tambah Topic',
        child: const Icon(Icons.add),
      ),
      body: topicsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (topics) {
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
              child: Text('Belum ada topic. Silakan buat topic baru.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              final topicPath = '$rootPath/${topic.name}';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    Icons.folder_open,
                    color: Colors.purple.shade300,
                  ),
                  title: Text(topic.name),
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
    );
  }
}

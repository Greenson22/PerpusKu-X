// lib/presentation/pages/subjects_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '/presentation/pages/contents_page.dart';
import '../providers/subject_provider.dart';

class SubjectsPage extends ConsumerWidget {
  final String topicName;
  final String topicPath;

  const SubjectsPage({
    super.key,
    required this.topicName,
    required this.topicPath,
  });

  // Dialog untuk menambah/mengubah nama subject
  void _showSubjectDialog(
    BuildContext context,
    WidgetRef ref, {
    String? oldSubjectPath,
    String? oldSubjectName,
  }) {
    final isEditing = oldSubjectPath != null;
    final titleController = TextEditingController(text: oldSubjectName ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Ubah Nama Subject' : 'Buat Subject Baru'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Nama Subject',
                hintText: 'Contoh: Bab 1 - Pengenalan',
              ),
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama subject tidak boleh kosong';
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
                  final subjectName = titleController.text;
                  final mutation = ref.read(subjectMutationProvider(topicPath));

                  try {
                    if (isEditing) {
                      await mutation.renameSubject(
                        oldSubjectPath!,
                        subjectName,
                      );
                    } else {
                      await mutation.createSubject(subjectName);
                    }
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Subject berhasil ${isEditing ? 'diubah' : 'dibuat'}!',
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
    String subjectPath,
    String subjectName,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Subject'),
          content: Text(
            'Apakah Anda yakin ingin menghapus subject "$subjectName"?\nSemua konten di dalamnya juga akan terhapus.',
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
                  await ref
                      .read(subjectMutationProvider(topicPath))
                      .deleteSubject(subjectPath);
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Subject berhasil dihapus.'),
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
    final subjectsAsyncValue = ref.watch(subjectsProvider(topicPath));

    return Scaffold(
      appBar: AppBar(title: Text(topicName)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectDialog(context, ref),
        tooltip: 'Tambah Subject',
        child: const Icon(Icons.add),
      ),
      body: subjectsAsyncValue.when(
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
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: Text('Belum ada subject. Silakan buat subject baru.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final subjectPath = '$topicPath/${subject.name}';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    Icons.article_outlined,
                    color: Colors.orange.shade300,
                  ),
                  title: Text(subject.name),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContentsPage(
                          subjectName: subject.name,
                          subjectPath: subjectPath,
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
                              _showSubjectDialog(
                                context,
                                ref,
                                oldSubjectPath: subjectPath,
                                oldSubjectName: subject.name,
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
                                subjectPath,
                                subject.name,
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

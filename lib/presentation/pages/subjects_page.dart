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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubjectDialog(context, ref),
        tooltip: 'Tambah Subject',
        icon: const Icon(Icons.add),
        label: const Text('Buat Subject'),
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
            return const _EmptyState(
              icon: Icons.article_outlined,
              message: 'Belum ada subject.\nSilakan buat subject baru.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              final subjectPath = '$topicPath/${subject.name}';
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: Icon(
                    Icons.article_outlined,
                    size: 40,
                    color: Colors.orange.shade700,
                  ),
                  title: Text(
                    subject.name,
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

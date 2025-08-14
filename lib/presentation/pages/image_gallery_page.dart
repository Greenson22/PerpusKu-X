// lib/presentation/pages/image_gallery_page.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- DITAMBAHKAN untuk Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/data/models/image_file_model.dart';
import 'package:my_perpusku/presentation/providers/content_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class ImageGalleryPage extends ConsumerWidget {
  final String subjectName;
  final String subjectPath;

  const ImageGalleryPage({
    super.key,
    required this.subjectName,
    required this.subjectPath,
  });

  // Fungsi untuk membuka gambar
  Future<void> _openImage(BuildContext context, String imagePath) async {
    final result = await OpenFile.open(imagePath);
    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka gambar: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi untuk menambah gambar baru
  Future<void> _addImage(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null && result.files.single.path != null) {
        final sourceFile = File(result.files.single.path!);
        await ref
            .read(contentMutationProvider)
            .addImage(subjectPath, sourceFile);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gambar berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi untuk menampilkan dialog ubah nama
  void _showRenameDialog(BuildContext context, WidgetRef ref, ImageFile image) {
    final oldNameWithoutExtension = path.basenameWithoutExtension(image.name);
    final controller = TextEditingController(text: oldNameWithoutExtension);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Gambar'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nama baru (tanpa ekstensi)',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama tidak boleh kosong';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(contentMutationProvider)
                      .renameImage(
                        image.path,
                        controller.text.trim(),
                        subjectPath,
                      );
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Nama gambar berhasil diubah.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengubah nama: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mengganti gambar
  Future<void> _replaceImage(
    BuildContext context,
    WidgetRef ref,
    ImageFile image,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null && result.files.single.path != null) {
        final newSourceFile = File(result.files.single.path!);
        await ref
            .read(contentMutationProvider)
            .replaceImage(image.path, newSourceFile, subjectPath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gambar berhasil diganti!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengganti gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fungsi untuk menampilkan dialog konfirmasi hapus
  void _showDeleteConfirmationDialog(
    BuildContext context,
    WidgetRef ref,
    ImageFile image,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Gambar'),
        content: Text(
          'Apakah Anda yakin ingin menghapus gambar "${image.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(contentMutationProvider)
                    .deleteImage(image.path, subjectPath);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Gambar berhasil dihapus.'),
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI YANG DIPERBARUI ---
  void _showOptions(BuildContext context, WidgetRef ref, ImageFile image) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: <Widget>[
          // Tombol Salin Path (Baru)
          ListTile(
            leading: const Icon(Icons.copy_outlined),
            title: const Text('Salin Path untuk Konten'),
            onTap: () {
              // Membuat path relatif: "images/nama_file.ext"
              final relativePath = 'images/${image.name}';
              // Menyalin path ke clipboard
              Clipboard.setData(ClipboardData(text: relativePath));
              // Tutup bottom sheet
              Navigator.pop(ctx);
              // Tampilkan notifikasi
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Path gambar disalin ke clipboard!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz_outlined),
            title: const Text('Ganti Gambar'),
            onTap: () {
              Navigator.pop(ctx);
              _replaceImage(context, ref, image);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Ubah Nama'),
            onTap: () {
              Navigator.pop(ctx);
              _showRenameDialog(context, ref, image);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(ctx);
              _showDeleteConfirmationDialog(context, ref, image);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagesAsyncValue = ref.watch(imagesProvider(subjectPath));

    return Scaffold(
      appBar: AppBar(title: Text('Galeri: $subjectName')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addImage(context, ref),
        tooltip: 'Tambah Gambar',
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
      body: imagesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (images) {
          if (images.isEmpty) {
            return const _EmptyState(
              icon: Icons.image_not_supported_outlined,
              message:
                  'Belum ada gambar di galeri ini.\nKetuk tombol + untuk menambah gambar pertama.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images.elementAt(index);
              return GestureDetector(
                onTap: () => _openImage(context, image.path),
                onLongPress: () => _showOptions(context, ref, image),
                child: GridTile(
                  footer: GridTileBar(
                    backgroundColor: Colors.black45,
                    title: Text(
                      image.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(image.path),
                      key: UniqueKey(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
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

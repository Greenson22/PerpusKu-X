// lib/presentation/pages/image_gallery_page.dart

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/presentation/providers/content_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class ImageGalleryPage extends ConsumerStatefulWidget {
  final String subjectName;
  final String subjectPath;

  const ImageGalleryPage({
    super.key,
    required this.subjectName,
    required this.subjectPath,
  });

  @override
  ConsumerState<ImageGalleryPage> createState() => _ImageGalleryPageState();
}

class _ImageGalleryPageState extends ConsumerState<ImageGalleryPage> {
  late String currentPath;
  late String rootImagesPath;

  @override
  void initState() {
    super.initState();
    rootImagesPath = path.join(widget.subjectPath, 'images');
    currentPath = rootImagesPath;
  }

  String getRelativePath(String fullPath) {
    // Membuat path relatif dari folder /images
    // contoh: "subfolder/gambar.jpg"
    return path.relative(fullPath, from: rootImagesPath);
  }

  Future<void> _openImage(String imagePath) async {
    final result = await OpenFile.open(imagePath);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka gambar: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null && result.files.single.path != null) {
        final sourceFile = File(result.files.single.path!);
        await ref
            .read(contentMutationProvider)
            .addImage(currentPath, sourceFile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gambar berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Folder Baru'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama Folder'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Nama tidak boleh kosong'
                : null,
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
                      .createGalleryFolder(currentPath, controller.text.trim());
                  navigator.pop();
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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showOptions(FileSystemEntity entity) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        if (entity is File) {
          return _FileOptions(
            onCopyPath: () {
              final relativePath = getRelativePath(entity.path);
              Clipboard.setData(ClipboardData(text: relativePath));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Path gambar disalin!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            onRename: () {
              Navigator.pop(ctx);
              _showRenameDialog(entity);
            },
            onDelete: () {
              Navigator.pop(ctx);
              _showDeleteConfirmationDialog(entity);
            },
          );
        } else if (entity is Directory) {
          return _FolderOptions(
            onRename: () {
              Navigator.pop(ctx);
              _showRenameFolderDialog(entity);
            },
            onDelete: () {
              Navigator.pop(ctx);
              _showDeleteFolderDialog(entity);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showRenameDialog(File file) {
    final oldName = path.basenameWithoutExtension(file.path);
    final controller = TextEditingController(text: oldName);
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
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Nama tidak boleh kosong'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            child: const Text('Simpan'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(contentMutationProvider)
                      .renameImage(
                        file.path,
                        controller.text.trim(),
                        path.dirname(file.path),
                      );
                  navigator.pop();
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
      ),
    );
  }

  void _showRenameFolderDialog(Directory folder) {
    final oldName = path.basename(folder.path);
    final controller = TextEditingController(text: oldName);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Nama Folder'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nama folder baru'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Nama tidak boleh kosong'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            child: const Text('Simpan'),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await ref
                      .read(contentMutationProvider)
                      .renameGalleryFolder(folder.path, controller.text.trim());
                  navigator.pop();
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
      ),
    );
  }

  void _showDeleteConfirmationDialog(File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Gambar'),
        content: Text(
          'Yakin ingin menghapus gambar "${path.basename(file.path)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(contentMutationProvider)
                    .deleteImage(file.path, path.dirname(file.path));
                navigator.pop();
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(Directory folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Folder'),
        content: Text(
          'Yakin ingin menghapus folder "${path.basename(folder.path)}" dan semua isinya? Aksi ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(contentMutationProvider)
                    .deleteGalleryFolder(folder.path);
                navigator.pop();
              } catch (e) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entitiesAsyncValue = ref.watch(galleryEntitiesProvider(currentPath));
    final bool isSubdirectory = currentPath != rootImagesPath;
    final currentFolderName = isSubdirectory
        ? path.basename(currentPath)
        : 'Galeri: ${widget.subjectName}';

    return Scaffold(
      appBar: AppBar(
        leading: isSubdirectory
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali',
                onPressed: () =>
                    setState(() => currentPath = path.dirname(currentPath)),
              )
            : null,
        title: Text(currentFolderName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Buat Folder Baru',
            onPressed: _showCreateFolderDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addImage,
        tooltip: 'Tambah Gambar',
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
      body: entitiesAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (entities) {
          if (entities.isEmpty) {
            return const _EmptyState(
              icon: Icons.image_not_supported_outlined,
              message:
                  'Folder ini kosong.\nKetuk tombol + untuk menambah gambar atau buat folder baru.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
            ),
            itemCount: entities.length,
            itemBuilder: (context, index) {
              final entity = entities[index];
              final name = path.basename(entity.path);

              // --- BAGIAN YANG DIPERBAIKI ---
              Widget tileContent;
              if (entity is Directory) {
                tileContent = const Icon(
                  Icons.folder_rounded,
                  size: 80,
                  color: Colors.amber,
                );
              } else if (entity is File) {
                // Di sini, 'entity' sudah pasti bertipe 'File'
                tileContent = Image.file(
                  entity,
                  key: ValueKey(entity.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                );
              } else {
                // Seharusnya tidak pernah terjadi
                tileContent = const SizedBox.shrink();
              }
              // --- AKHIR BAGIAN YANG DIPERBAIKI ---

              return GestureDetector(
                onTap: () {
                  if (entity is Directory) {
                    setState(() => currentPath = entity.path);
                  } else if (entity is File) {
                    _openImage(entity.path);
                  }
                },
                onLongPress: () => _showOptions(entity),
                child: GridTile(
                  footer: GridTileBar(
                    backgroundColor: Colors.black45,
                    title: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: tileContent,
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

class _FileOptions extends StatelessWidget {
  final VoidCallback onCopyPath;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _FileOptions({
    required this.onCopyPath,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        ListTile(
          leading: const Icon(Icons.copy_outlined),
          title: const Text('Salin Path untuk Konten'),
          onTap: onCopyPath,
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Ubah Nama'),
          onTap: onRename,
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Hapus', style: TextStyle(color: Colors.red)),
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _FolderOptions extends StatelessWidget {
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _FolderOptions({required this.onRename, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Ubah Nama'),
          onTap: onRename,
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Hapus', style: TextStyle(color: Colors.red)),
          onTap: onDelete,
        ),
      ],
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

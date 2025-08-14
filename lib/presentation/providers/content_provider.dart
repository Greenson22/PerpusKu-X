// lib/presentation/providers/content_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart'
    as path; // <-- PERBAIKAN: Import ditambahkan di sini
import '../../data/models/content_model.dart';
import '../../data/models/image_file_model.dart';
import '../../data/services/content_service.dart';

final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

final contentSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider untuk mengambil data konten (HTML)
final contentsProvider = FutureProvider.family<List<Content>, String>((
  ref,
  subjectPath,
) async {
  final contentService = ref.watch(contentServiceProvider);
  final allContents = await contentService.getContents(subjectPath);
  final searchQuery = ref.watch(contentSearchQueryProvider);

  if (searchQuery.isEmpty) {
    return allContents;
  }

  return allContents
      .where(
        (content) =>
            content.title.toLowerCase().contains(searchQuery.toLowerCase()),
      )
      .toList();
});

// Provider untuk mengambil entitas galeri (folder & file)
final galleryEntitiesProvider =
    FutureProvider.family<List<FileSystemEntity>, String>((
      ref,
      directoryPath,
    ) async {
      final contentService = ref.watch(contentServiceProvider);
      return contentService.getGalleryEntities(directoryPath);
    });

// Provider untuk mengambil data gambar (opsional, bisa dihapus jika tidak digunakan di tempat lain)
final imagesProvider = FutureProvider.family<List<ImageFile>, String>((
  ref,
  subjectPath,
) async {
  final contentService = ref.watch(contentServiceProvider);
  final imagesDir = await contentService.ensureImagesDirectoryExists(
    subjectPath,
  );
  final entities = await contentService.getGalleryEntities(imagesDir.path);
  // Ini hanya akan mengembalikan file, bukan folder.
  return entities
      .whereType<File>()
      .map((file) => ImageFile(name: path.basename(file.path), path: file.path))
      .toList();
});

// Provider untuk menangani aksi/mutasi
final contentMutationProvider = Provider((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return ContentMutation(contentService: contentService, ref: ref);
});

class ContentMutation {
  final ContentService contentService;
  final Ref ref;

  ContentMutation({required this.contentService, required this.ref});

  Future<void> createContent(String subjectPath, String title) async {
    await contentService.createContent(subjectPath, title);
    ref.invalidate(contentsProvider(subjectPath));
  }

  Future<void> addImage(String directoryPath, File sourceFile) async {
    await contentService.addImage(directoryPath, sourceFile);
    ref.invalidate(galleryEntitiesProvider(directoryPath));
  }

  Future<void> renameImage(
    String oldImagePath,
    String newImageName,
    String parentPath,
  ) async {
    await contentService.renameImage(oldImagePath, newImageName);
    ref.invalidate(galleryEntitiesProvider(parentPath));
  }

  Future<void> deleteImage(String imagePath, String parentPath) async {
    await contentService.deleteImage(imagePath);
    ref.invalidate(galleryEntitiesProvider(parentPath));
  }

  Future<void> replaceImage(
    String oldImagePath,
    File newSourceFile,
    String parentPath,
  ) async {
    await contentService.replaceImage(oldImagePath, newSourceFile);
    ref.invalidate(galleryEntitiesProvider(parentPath));
  }

  Future<void> createGalleryFolder(
    String currentPath,
    String folderName,
  ) async {
    await contentService.createGalleryFolder(currentPath, folderName);
    ref.invalidate(galleryEntitiesProvider(currentPath));
  }

  Future<void> renameGalleryFolder(
    String oldFolderPath,
    String newFolderName,
  ) async {
    await contentService.renameGalleryFolder(oldFolderPath, newFolderName);
    ref.invalidate(galleryEntitiesProvider(path.dirname(oldFolderPath)));
  }

  Future<void> deleteGalleryFolder(String folderPath) async {
    await contentService.deleteGalleryFolder(folderPath);
    ref.invalidate(galleryEntitiesProvider(path.dirname(folderPath)));
  }
}

// lib/presentation/providers/content_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/data/services/gallery_service.dart';
import 'package:my_perpusku/data/services/html_service.dart';
import 'package:path/path.dart' as path;
import '../../data/models/content_model.dart';
import '../../data/models/image_file_model.dart';
import '../../data/services/content_service.dart';

// --- PENYESUAIAN DI SINI: BUAT PROVIDER UNTUK SETIAP LAYANAN ---

/// Provider untuk layanan yang mengelola konten HTML (metadata.json).
final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

/// Provider untuk layanan yang mengelola galeri (file & folder gambar).
final galleryServiceProvider = Provider<GalleryService>((ref) {
  return GalleryService();
});

/// Provider untuk layanan yang memproses file HTML untuk ditampilkan.
final htmlServiceProvider = Provider<HtmlService>((ref) {
  return HtmlService();
});

// --- AKHIR PENYESUAIAN ---

final contentSearchQueryProvider = StateProvider<String>((ref) => '');

final contentsProvider = FutureProvider.family<List<Content>, String>((
  ref,
  subjectPath,
) async {
  // Panggil provider layanan yang sesuai
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

final galleryEntitiesProvider =
    FutureProvider.family<List<FileSystemEntity>, String>((
      ref,
      directoryPath,
    ) async {
      // Panggil provider layanan yang sesuai
      final galleryService = ref.watch(galleryServiceProvider);
      return galleryService.getGalleryEntities(directoryPath);
    });

final galleryFolderProvider = FutureProvider.family<List<Directory>, String>((
  ref,
  directoryPath,
) async {
  // Panggil provider layanan yang sesuai
  final galleryService = ref.watch(galleryServiceProvider);
  return galleryService.getGalleryFolders(directoryPath);
});

final imagesProvider = FutureProvider.family<List<ImageFile>, String>((
  ref,
  subjectPath,
) async {
  // Panggil provider layanan yang sesuai
  final galleryService = ref.watch(galleryServiceProvider);
  final imagesDir = await galleryService.ensureImagesDirectoryExists(
    subjectPath,
  );
  final entities = await galleryService.getGalleryEntities(imagesDir.path);
  return entities
      .whereType<File>()
      .map((file) => ImageFile(name: path.basename(file.path), path: file.path))
      .toList();
});

// --- PENYESUAIAN DI SINI: INJEKSI SEMUA LAYANAN KE DALAM MUTATION ---

/// Provider untuk kelas mutasi yang akan menangani semua aksi (CUD).
final contentMutationProvider = Provider((ref) {
  // Ambil semua layanan yang dibutuhkan
  final contentService = ref.watch(contentServiceProvider);
  final galleryService = ref.watch(galleryServiceProvider);
  final htmlService = ref.watch(htmlServiceProvider);

  // Kirim semua layanan ke konstruktor
  return ContentMutation(
    contentService: contentService,
    galleryService: galleryService,
    htmlService: htmlService,
    ref: ref,
  );
});

class ContentMutation {
  final ContentService contentService;
  final GalleryService galleryService;
  final HtmlService htmlService;
  final Ref ref;

  ContentMutation({
    required this.contentService,
    required this.galleryService,
    required this.htmlService,
    required this.ref,
  });

  // --- Metode di bawah ini sekarang mendelegasikan ke layanan yang benar ---

  // == ContentService Methods ==
  Future<void> createContent(String subjectPath, String title) async {
    await contentService.createContent(subjectPath, title);
    ref.invalidate(contentsProvider(subjectPath));
  }

  Future<void> renameContentTitle(String contentPath, String newTitle) async {
    await contentService.renameContentTitle(contentPath, newTitle);
    ref.invalidate(contentsProvider(path.dirname(contentPath)));
  }

  // == HtmlService Method ==
  Future<String> createMergedHtmlFile(String contentPath) async {
    return htmlService.createMergedHtmlFile(contentPath);
  }

  // == GalleryService Methods ==
  Future<void> addImage(String directoryPath, File sourceFile) async {
    await galleryService.addImage(directoryPath, sourceFile);
    ref.invalidate(galleryEntitiesProvider(directoryPath));
  }

  Future<void> renameImage(
    String oldImagePath,
    String newImageName,
    String parentPath,
  ) async {
    await galleryService.renameImage(oldImagePath, newImageName);
    ref.invalidate(galleryEntitiesProvider(parentPath));
  }

  Future<void> deleteImage(String imagePath, String parentPath) async {
    await galleryService.deleteImage(imagePath);
    ref.invalidate(galleryEntitiesProvider(parentPath));
  }

  Future<void> replaceImage(
    String oldImagePath,
    File newSourceFile,
    String parentPath,
  ) async {
    await galleryService.replaceImage(oldImagePath, newSourceFile);
    ref.invalidate(galleryEntitiesProvider(parentPath));
  }

  Future<void> createGalleryFolder(
    String currentPath,
    String folderName,
  ) async {
    await galleryService.createGalleryFolder(currentPath, folderName);
    ref.invalidate(galleryEntitiesProvider(currentPath));
  }

  Future<void> renameGalleryFolder(
    String oldFolderPath,
    String newFolderName,
  ) async {
    await galleryService.renameGalleryFolder(oldFolderPath, newFolderName);
    ref.invalidate(galleryEntitiesProvider(path.dirname(oldFolderPath)));
  }

  Future<void> deleteGalleryFolder(String folderPath) async {
    await galleryService.deleteGalleryFolder(folderPath);
    ref.invalidate(galleryEntitiesProvider(path.dirname(folderPath)));
  }

  Future<void> moveEntity(
    FileSystemEntity entity,
    String destinationPath,
  ) async {
    final sourcePath = path.dirname(entity.path);
    await galleryService.moveEntity(entity, destinationPath);
    ref.invalidate(galleryEntitiesProvider(sourcePath));
    ref.invalidate(galleryEntitiesProvider(destinationPath));
  }
}

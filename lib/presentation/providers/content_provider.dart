// lib/presentation/providers/content_provider.dart

import 'dart:io'; // Import dart:io
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/content_model.dart';
import '../../data/models/image_file_model.dart';
import '../../data/services/content_service.dart';

// ... (provider yang sudah ada tidak berubah) ...
final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

final contentSearchQueryProvider = StateProvider<String>((ref) => '');

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

final imagesProvider = FutureProvider.family<List<ImageFile>, String>((
  ref,
  subjectPath,
) async {
  final contentService = ref.watch(contentServiceProvider);
  return contentService.getImages(subjectPath);
});

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

  /// --- METODE MUTASI BARU UNTUK GAMBAR ---

  Future<void> addImage(String subjectPath, File sourceFile) async {
    await contentService.addImage(subjectPath, sourceFile);
    // Invalidate provider gambar agar UI diperbarui
    ref.invalidate(imagesProvider(subjectPath));
  }

  Future<void> renameImage(
    String oldImagePath,
    String newImageName,
    String subjectPath,
  ) async {
    await contentService.renameImage(oldImagePath, newImageName);
    ref.invalidate(imagesProvider(subjectPath));
  }

  Future<void> deleteImage(String imagePath, String subjectPath) async {
    await contentService.deleteImage(imagePath);
    ref.invalidate(imagesProvider(subjectPath));
  }
}

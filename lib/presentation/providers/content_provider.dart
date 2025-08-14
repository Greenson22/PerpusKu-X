// lib/presentation/providers/content_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/content_model.dart';
import '../../data/models/image_file_model.dart'; // Import model image
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

// Provider baru untuk mengambil data gambar
final imagesProvider = FutureProvider.family<List<ImageFile>, String>((
  ref,
  subjectPath,
) async {
  final contentService = ref.watch(contentServiceProvider);
  return contentService.getImages(subjectPath);
});

// Provider untuk mutasi (tidak berubah)
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
}

// lib/presentation/providers/content_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/content_model.dart';
import '../../data/services/content_service.dart';

final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

final contentSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider untuk mengambil data (tidak berubah)
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

// 1. Tambahkan provider baru untuk menangani aksi/mutasi
final contentMutationProvider = Provider((ref) {
  final contentService = ref.watch(contentServiceProvider);
  return ContentMutation(contentService: contentService, ref: ref);
});

class ContentMutation {
  final ContentService contentService;
  final Ref ref;

  ContentMutation({required this.contentService, required this.ref});

  // 2. Metode untuk memicu pembuatan konten dan me-refresh provider
  Future<void> createContent(String subjectPath, String title) async {
    await contentService.createContent(subjectPath, title);
    // 3. Refresh/invalidate provider agar UI mengambil data terbaru
    ref.invalidate(contentsProvider(subjectPath));
  }
}

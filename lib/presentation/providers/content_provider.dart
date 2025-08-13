// lib/presentation/providers/content_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/content_model.dart';
import '../../data/services/content_service.dart';

final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

// 1. Tambahkan StateProvider untuk menampung query pencarian
final contentSearchQueryProvider = StateProvider<String>((ref) => '');

final contentsProvider = FutureProvider.family<List<Content>, String>((
  ref,
  subjectPath,
) async {
  final contentService = ref.watch(contentServiceProvider);
  // 2. Dapatkan daftar konten asli dari service
  final allContents = await contentService.getContents(subjectPath);
  // 3. Dapatkan query pencarian saat ini
  final searchQuery = ref.watch(contentSearchQueryProvider);

  // 4. Jika query pencarian kosong, kembalikan semua konten
  if (searchQuery.isEmpty) {
    return allContents;
  }

  // 5. Jika tidak, filter daftar konten berdasarkan judul
  return allContents
      .where(
        (content) =>
            content.title.toLowerCase().contains(searchQuery.toLowerCase()),
      )
      .toList();
});

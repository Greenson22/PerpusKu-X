// lib/presentation/providers/content_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/content_model.dart';
import '../../data/services/content_service.dart';

final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

final contentsProvider = FutureProvider.family<List<Content>, String>((
  ref,
  subjectPath,
) async {
  final contentService = ref.watch(contentServiceProvider);
  return contentService.getContents(subjectPath);
});

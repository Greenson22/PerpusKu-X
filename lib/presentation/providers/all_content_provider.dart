// lib/presentation/providers/all_content_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/data/services/content_service.dart';
import 'package:my_perpusku/data/services/subject_service.dart';
import 'package:my_perpusku/data/services/topic_service.dart';
import 'package:my_perpusku/presentation/providers/directory_provider.dart';

/// Provider untuk mengambil semua judul konten dari seluruh direktori.
///
/// Provider ini akan secara otomatis menelusuri struktur folder:
/// Topics -> Subjects -> Contents, lalu mengumpulkan semua judulnya.
final allContentTitlesProvider = FutureProvider<List<String>>((ref) async {
  final rootPath = ref.watch(rootDirectoryProvider);
  if (rootPath == null || rootPath.isEmpty) {
    return []; // Jika path utama belum diatur, kembalikan list kosong.
  }

  // Inisialisasi service yang dibutuhkan.
  final topicService = TopicService();
  final subjectService = SubjectService();
  final contentService = ContentService();

  final List<String> allTitles = [];

  try {
    // 1. Dapatkan semua folder topik.
    final topics = await topicService.getTopics(rootPath);

    // 2. Iterasi setiap topik untuk mendapatkan subjek di dalamnya.
    for (final topic in topics) {
      final topicPath = '$rootPath${Platform.pathSeparator}${topic.name}';
      final subjects = await subjectService.getSubjects(topicPath);

      // 3. Iterasi setiap subjek untuk mendapatkan file konten.
      for (final subject in subjects) {
        final subjectPath =
            '$topicPath${Platform.pathSeparator}${subject.name}';
        final contents = await contentService.getContents(subjectPath);

        // 4. Ekstrak judul dari setiap konten dan tambahkan ke list.
        for (final content in contents) {
          allTitles.add(content.title);
        }
      }
    }
  } catch (e) {
    // Jika terjadi error saat membaca direktori, cetak error dan kembalikan list kosong.
    print('Error saat mengambil semua judul konten: $e');
    return [];
  }

  return allTitles;
});

// lib/presentation/providers/all_content_provider.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/data/models/topic_model.dart';
import 'package:my_perpusku/data/services/content_service.dart';
import 'package:my_perpusku/data/services/subject_service.dart';
import 'package:my_perpusku/data/services/topic_service.dart';
import 'package:my_perpusku/presentation/providers/directory_provider.dart';
import 'package:my_perpusku/presentation/providers/topic_filter_provider.dart';

/// Provider untuk mengambil semua judul konten berdasarkan filter topik yang aktif.
final allContentTitlesProvider = FutureProvider<List<String>>((ref) async {
  final rootPath = ref.watch(rootDirectoryProvider);
  // Awasi (watch) provider filter untuk mendapatkan pilihan terbaru.
  final topicFilter = ref.watch(topicFilterProvider);

  if (rootPath == null || rootPath.isEmpty) {
    return [];
  }

  final topicService = TopicService();
  final subjectService = SubjectService();
  final contentService = ContentService();

  final List<String> allTitles = [];

  try {
    List<Topic> topicsToScan;
    // Dapatkan semua topik yang ada untuk dibandingkan dengan filter.
    final allTopics = await topicService.getTopics(rootPath);

    if (topicFilter.contains(allTopicsKey)) {
      // Jika "Semua Topik" dipilih, pindai semuanya.
      topicsToScan = allTopics;
    } else {
      // Jika tidak, saring topik berdasarkan daftar yang ada di filter.
      topicsToScan = allTopics
          .where((t) => topicFilter.contains(t.name))
          .toList();
    }

    // Lakukan iterasi hanya pada topik yang telah difilter.
    for (final topic in topicsToScan) {
      final topicPath = '$rootPath${Platform.pathSeparator}${topic.name}';
      final subjects = await subjectService.getSubjects(topicPath);

      for (final subject in subjects) {
        final subjectPath =
            '$topicPath${Platform.pathSeparator}${subject.name}';
        final contents = await contentService.getContents(subjectPath);

        for (final content in contents) {
          allTitles.add(content.title);
        }
      }
    }
  } catch (e) {
    print('Error saat mengambil semua judul konten: $e');
    return [];
  }

  return allTitles;
});

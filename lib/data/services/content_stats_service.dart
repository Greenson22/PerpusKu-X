// lib/data/services/content_stats_service.dart

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:my_perpusku/data/models/content_model.dart';
import 'package:my_perpusku/data/models/content_stats_model.dart';
import 'package:my_perpusku/data/services/content_service.dart';
import 'package:my_perpusku/data/services/gallery_service.dart';

class ContentStatsService {
  final ContentService _contentService;
  final GalleryService _galleryService;

  ContentStatsService(this._contentService, this._galleryService);

  Future<ContentStats> getStats(String subjectPath) async {
    // 1. Get all content files to calculate count and size
    final List<Content> contents = await _contentService.getContents(
      subjectPath,
    );
    int totalSize = 0;
    for (final content in contents) {
      final file = File(content.path);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }

    // 2. Get index.html last modified date
    DateTime? indexLastModified;
    final indexFile = File(path.join(subjectPath, 'index.html'));
    if (await indexFile.exists()) {
      indexLastModified = await indexFile.lastModified();
    }

    // 3. Get gallery stats
    final galleryStats = await _galleryService.getGalleryStats(subjectPath);

    return ContentStats(
      contentCount: contents.length,
      totalContentSize: totalSize,
      indexLastModified: indexLastModified,
      galleryStats: galleryStats,
    );
  }
}

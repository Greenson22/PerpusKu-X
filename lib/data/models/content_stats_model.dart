// lib/data/models/content_stats_model.dart

import 'dart:io';

class ContentStats {
  final int contentCount;
  final int totalContentSize; // in bytes
  final DateTime? indexLastModified;
  final GalleryStats galleryStats;

  ContentStats({
    required this.contentCount,
    required this.totalContentSize,
    this.indexLastModified,
    required this.galleryStats,
  });
}

class GalleryStats {
  final int imageCount;
  final int folderCount;

  GalleryStats({required this.imageCount, required this.folderCount});
}

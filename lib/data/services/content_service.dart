// lib/data/services/content_service.dart

import 'dart:io';
import '../models/content_model.dart';

class ContentService {
  Future<List<Content>> getContents(String subjectPath) async {
    final directory = Directory(subjectPath);

    if (!await directory.exists()) {
      throw Exception(
        'Error: Direktori tidak dapat ditemukan di path:\n$subjectPath',
      );
    }

    final List<Content> contents = [];
    final Stream<FileSystemEntity> entities = directory.list();

    await for (final entity in entities) {
      // Filter hanya untuk file dengan ekstensi .html dan bukan index.html
      if (entity is File && entity.path.endsWith('.html')) {
        final fileName = entity.path.split(Platform.pathSeparator).last;
        if (fileName != 'index.html') {
          contents.add(Content(name: fileName, path: entity.path));
        }
      }
    }

    // Urutkan hasil berdasarkan abjad
    contents.sort((a, b) => a.name.compareTo(b.name));
    return contents;
  }
}

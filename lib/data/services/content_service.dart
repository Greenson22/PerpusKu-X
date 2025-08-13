// lib/data/services/content_service.dart

import 'dart:convert'; // 1. Tambahkan import untuk JSON
import 'dart:io';
import '../models/content_model.dart';

class ContentService {
  Future<List<Content>> getContents(String subjectPath) async {
    final directory = Directory(subjectPath);
    final metadataFile = File(
      '$subjectPath/metadata.json',
    ); // Path ke metadata.json

    if (!await directory.exists()) {
      throw Exception(
        'Error: Direktori tidak dapat ditemukan di path:\n$subjectPath',
      );
    }

    if (!await metadataFile.exists()) {
      throw Exception(
        'Error: File metadata.json tidak ditemukan di:\n$subjectPath',
      );
    }

    // 2. Baca dan parse file metadata.json
    final metadataString = await metadataFile.readAsString();
    final metadataJson = json.decode(metadataString);
    final List<dynamic> contentList = metadataJson['content'];

    // 3. Buat Map untuk memetakan nama_file ke judul agar pencarian lebih cepat
    final titleMap = {
      for (var item in contentList)
        item['nama_file'] as String: item['judul'] as String,
    };

    final List<Content> contents = [];
    final Stream<FileSystemEntity> entities = directory.list();

    await for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.html')) {
        final fileName = entity.path.split(Platform.pathSeparator).last;

        // 4. Dapatkan judul dari Map menggunakan nama file
        final title = titleMap[fileName];

        // 5. Hanya tambahkan konten jika ada di metadata.json
        if (title != null) {
          contents.add(
            Content(
              name: fileName, // Nama file asli
              path: entity.path, // Path lengkap ke file
              title: title, // Judul dari metadata
            ),
          );
        }
      }
    }

    // 6. Urutkan daftar berdasarkan judul (bukan nama file)
    contents.sort((a, b) => a.title.compareTo(b.title));
    return contents;
  }
}

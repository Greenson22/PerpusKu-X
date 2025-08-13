// lib/data/services/content_service.dart

import 'dart:convert'; // Import untuk JSON
import 'dart:io';
import 'package:uuid/uuid.dart'; // 1. Import package uuid
import '../models/content_model.dart';

class ContentService {
  // Method getContents tetap sama ...
  Future<List<Content>> getContents(String subjectPath) async {
    final directory = Directory(subjectPath);
    final metadataFile = File('$subjectPath/metadata.json');

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

    final metadataString = await metadataFile.readAsString();
    final metadataJson = json.decode(metadataString);
    final List<dynamic> contentList = metadataJson['content'];

    final titleMap = {
      for (var item in contentList)
        item['nama_file'] as String: item['judul'] as String,
    };

    final List<Content> contents = [];
    final Stream<FileSystemEntity> entities = directory.list();

    await for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.html')) {
        final fileName = entity.path.split(Platform.pathSeparator).last;
        final title = titleMap[fileName];
        if (title != null) {
          contents.add(
            Content(name: fileName, path: entity.path, title: title),
          );
        }
      }
    }
    contents.sort((a, b) => a.title.compareTo(b.title));
    return contents;
  }

  // 2. Tambahkan metode baru untuk membuat konten
  Future<void> createContent(String subjectPath, String title) async {
    try {
      // 3. Buat nama file yang aman dari judul
      final sanitizedTitle = title
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_') // Ganti spasi dengan underscore
          .replaceAll(
            RegExp(r'[^a-z0-9_]'),
            '',
          ); // Hapus semua selain huruf, angka, dan underscore

      if (sanitizedTitle.isEmpty) {
        throw Exception("Judul tidak valid setelah dibersihkan.");
      }
      final fileName = '$sanitizedTitle.html';
      final filePath = '$subjectPath/$fileName';
      final file = File(filePath);

      // Cek apakah file sudah ada
      if (await file.exists()) {
        throw Exception("File dengan nama '$fileName' sudah ada.");
      }

      // 4. Update metadata.json
      final metadataFile = File('$subjectPath/metadata.json');
      if (!await metadataFile.exists()) {
        throw Exception(
          "metadata.json tidak ditemukan. Tidak dapat menambah konten baru.",
        );
      }

      final metadataString = await metadataFile.readAsString();
      final metadataJson = json.decode(metadataString) as Map<String, dynamic>;
      final contentList = metadataJson['content'] as List;

      // Buat entri baru
      final newContent = {
        "id": const Uuid().v4(), // 5. Hasilkan ID unik (UUID)
        "nama_file": fileName,
        "judul": title,
      };
      contentList.add(newContent);

      // Tulis kembali ke file metadata.json
      await metadataFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(metadataJson),
      );

      // 6. Buat file HTML baru dengan konten default
      await file.writeAsString('''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$title</title>
</head>
<body>
    <h1>$title</h1>
    <p>Ini adalah konten awal. Silakan ubah file ini.</p>
</body>
</html>
''');
    } catch (e) {
      // Melempar kembali error untuk ditangani oleh UI
      rethrow;
    }
  }
}

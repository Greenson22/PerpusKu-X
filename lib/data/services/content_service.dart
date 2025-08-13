// lib/data/services/content_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart'; // 1. Import path_provider
import 'package:uuid/uuid.dart';
import '../models/content_model.dart';

class ContentService {
  // Method getContents tidak berubah
  Future<List<Content>> getContents(String subjectPath) async {
    final directory = Directory(subjectPath);
    final metadataFile = File('$subjectPath/metadata.json');

    if (!await directory.exists()) {
      throw Exception(
        'Error: Direktori tidak dapat ditemukan di path:\n$subjectPath',
      );
    }
    if (!await metadataFile.exists()) {
      // Jika metadata tidak ada, kembalikan list kosong agar tidak error
      return [];
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
        // Jangan tampilkan index.html di dalam list
        if (fileName == 'index.html') continue;

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

  // Method createContent tidak berubah
  Future<void> createContent(String subjectPath, String title) async {
    try {
      final sanitizedTitle = title
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');

      if (sanitizedTitle.isEmpty) {
        throw Exception("Judul tidak valid setelah dibersihkan.");
      }
      final fileName = '$sanitizedTitle.html';
      final filePath = '$subjectPath/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        throw Exception("File dengan nama '$fileName' sudah ada.");
      }

      final metadataFile = File('$subjectPath/metadata.json');
      if (!await metadataFile.exists()) {
        throw Exception(
          "metadata.json tidak ditemukan. Tidak dapat menambah konten baru.",
        );
      }

      final metadataString = await metadataFile.readAsString();
      final metadataJson = json.decode(metadataString) as Map<String, dynamic>;
      final contentList = metadataJson['content'] as List;

      final newContent = {
        "id": const Uuid().v4(),
        "nama_file": fileName,
        "judul": title,
      };
      contentList.add(newContent);

      await metadataFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(metadataJson),
      );

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
      rethrow;
    }
  }

  // 2. TAMBAHKAN METHOD BARU UNTUK MENGGABUNGKAN FILE
  Future<String> createMergedHtmlFile(String contentPath) async {
    try {
      final contentFile = File(contentPath);
      // Dapatkan path folder subject dari path file konten
      final subjectPath = contentFile.parent.path;
      final indexPath = '$subjectPath/index.html';
      final indexFile = File(indexPath);

      if (!await indexFile.exists()) {
        throw Exception(
          'File "index.html" tidak ditemukan di folder subject: $subjectPath',
        );
      }
      if (!await contentFile.exists()) {
        throw Exception('File konten tidak ditemukan: $contentPath');
      }

      // 3. Baca kedua file
      final String indexContent = await indexFile.readAsString();
      final String mainContent = await contentFile.readAsString();

      // 4. Gabungkan konten menggunakan Regular Expression
      // Ini akan menggantikan <div id="main-container">...</div> dengan konten baru
      final mergedContent = indexContent.replaceFirst(
        RegExp(r'<div id="main-container">[\s\S]*?</div>'),
        '<div id="main-container">$mainContent</div>',
      );

      // 5. Buat file temporer
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/view.html');
      await tempFile.writeAsString(mergedContent);

      // 6. Kembalikan path dari file temporer
      return tempFile.path;
    } catch (e) {
      // Lempar kembali error untuk ditangani oleh UI
      rethrow;
    }
  }
}

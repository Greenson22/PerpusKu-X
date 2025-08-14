// lib/data/services/content_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // Pastikan uuid di-import
import '../models/content_model.dart';

class ContentService {
  // Metode getContents tidak berubah
  Future<List<Content>> getContents(String subjectPath) async {
    final directory = Directory(subjectPath);
    final metadataFile = File('$subjectPath/metadata.json');

    if (!await directory.exists()) {
      throw Exception(
        'Error: Direktori tidak dapat ditemukan di path:\n$subjectPath',
      );
    }
    if (!await metadataFile.exists()) {
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

  // Metode createContent tidak berubah (sudah benar, menghasilkan snippet)
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
<h1>$title</h1>
<p>Ini adalah konten awal. Silakan ubah file ini.</p>
''');
    } catch (e) {
      rethrow;
    }
  }

  // --- BAGIAN YANG DIPERBAIKI ---
  Future<String> createMergedHtmlFile(String contentPath) async {
    try {
      final contentFile = File(contentPath);
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

      final String indexContent = await indexFile.readAsString();
      final String mainContent = await contentFile.readAsString();

      final mergedContent = indexContent.replaceFirst(
        // Regex ini sudah benar untuk mengganti div yang kosong atau berisi
        RegExp(r'<div[^>]*id="main-container"[^>]*>[\s\S]*?</div>'),
        // Konten disisipkan di sini
        '<div id="main-container">$mainContent</div>',
      );

      final tempDir = await getTemporaryDirectory();
      // Membuat nama file unik untuk menghindari masalah cache
      final uniqueFileName = '${const Uuid().v4()}.html';
      final tempFile = File('${tempDir.path}/$uniqueFileName');
      await tempFile.writeAsString(mergedContent);

      // Mengembalikan path dari file temporer yang unik
      return tempFile.path;
    } catch (e) {
      rethrow;
    }
  }

  // --- AKHIR BAGIAN YANG DIPERBAIKI ---
}

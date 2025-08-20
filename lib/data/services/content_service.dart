// lib/data/services/content_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/content_model.dart';

class ContentService {
  /// Mengambil daftar konten (file HTML) dari direktori subject.
  Future<List<Content>> getContents(String subjectPath) async {
    final directory = Directory(subjectPath);
    final metadataFile = File(path.join(subjectPath, 'metadata.json'));

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
      if (entity is File && entity.path.toLowerCase().endsWith('.html')) {
        final fileName = path.basename(entity.path);
        if (fileName.toLowerCase() == 'index.html') continue;

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

  /// Membuat file konten HTML baru beserta metadatanya.
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
      final filePath = path.join(subjectPath, fileName);
      final file = File(filePath);

      if (await file.exists()) {
        throw Exception("File dengan nama '$fileName' sudah ada.");
      }

      final metadataFile = File(path.join(subjectPath, 'metadata.json'));
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

  /// Mengubah judul konten di dalam file metadata.
  Future<void> renameContentTitle(String contentPath, String newTitle) async {
    if (newTitle.trim().isEmpty) {
      throw Exception("Judul baru tidak boleh kosong.");
    }

    final subjectPath = path.dirname(contentPath);
    final fileName = path.basename(contentPath);
    final metadataFile = File(path.join(subjectPath, 'metadata.json'));

    if (!await metadataFile.exists()) {
      throw Exception("File metadata.json tidak ditemukan.");
    }

    final metadataString = await metadataFile.readAsString();
    final metadataJson = json.decode(metadataString) as Map<String, dynamic>;
    final contentList = metadataJson['content'] as List;

    int contentIndex = contentList.indexWhere(
      (c) => c['nama_file'] == fileName,
    );

    if (contentIndex == -1) {
      throw Exception("Konten tidak ditemukan di dalam metadata.");
    }

    contentList[contentIndex]['judul'] = newTitle;

    await metadataFile.writeAsString(
      JsonEncoder.withIndent('  ').convert(metadataJson),
    );
  }

  // --- KODE BARU DITAMBAHKAN DI SINI ---
  /// Menghapus file konten HTML dan metadatanya.
  Future<void> deleteContent(String contentPath) async {
    try {
      final fileToDelete = File(contentPath);
      if (!await fileToDelete.exists()) {
        throw Exception("File konten yang ingin dihapus tidak ditemukan.");
      }

      final subjectPath = path.dirname(contentPath);
      final fileName = path.basename(contentPath);
      final metadataFile = File(path.join(subjectPath, 'metadata.json'));

      if (!await metadataFile.exists()) {
        // Jika metadata tidak ada, hapus saja filenya
        await fileToDelete.delete();
        return;
      }

      // Hapus entri dari metadata.json
      final metadataString = await metadataFile.readAsString();
      final metadataJson = json.decode(metadataString) as Map<String, dynamic>;
      final contentList = metadataJson['content'] as List;

      contentList.removeWhere((c) => c['nama_file'] == fileName);

      await metadataFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(metadataJson),
      );

      // Hapus file fisiknya
      await fileToDelete.delete();
    } catch (e) {
      rethrow;
    }
  }

  // --- AKHIR KODE BARU ---
}

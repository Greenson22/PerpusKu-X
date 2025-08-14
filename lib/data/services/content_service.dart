// lib/data/services/content_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:my_perpusku/data/models/image_file_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/content_model.dart';

class ContentService {
  /// Memastikan direktori 'images' ada di dalam path subject.
  /// Jika tidak ada, maka akan dibuat.
  Future<Directory> ensureImagesDirectoryExists(String subjectPath) async {
    final imagesPath = '$subjectPath/images';
    final imagesDir = Directory(imagesPath);
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Mengambil daftar file gambar dari subdirektori 'images'.
  Future<List<ImageFile>> getImages(String subjectPath) async {
    final imagesDir = await ensureImagesDirectoryExists(subjectPath);
    final List<ImageFile> imageFiles = [];
    final Stream<FileSystemEntity> entities = imagesDir.list();

    await for (final entity in entities) {
      if (entity is File) {
        final fileName = entity.path.split(Platform.pathSeparator).last;
        // Filter untuk hanya menampilkan tipe gambar yang umum
        if ([
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.bmp',
          '.webp',
        ].any((ext) => fileName.toLowerCase().endsWith(ext))) {
          imageFiles.add(ImageFile(name: fileName, path: entity.path));
        }
      }
    }
    imageFiles.sort((a, b) => a.name.compareTo(b.name));
    return imageFiles;
  }

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

  // Metode createContent tidak berubah
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

  // Metode createMergedHtmlFile tidak berubah
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
        RegExp(r'<div[^>]*id="main-container"[^>]*>[\s\S]*?</div>'),
        '<div id="main-container">$mainContent</div>',
      );

      final tempDir = await getTemporaryDirectory();
      final uniqueFileName = '${const Uuid().v4()}.html';
      final tempFile = File('${tempDir.path}/$uniqueFileName');
      await tempFile.writeAsString(mergedContent);

      return tempFile.path;
    } catch (e) {
      rethrow;
    }
  }
}

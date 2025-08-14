// lib/data/services/content_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:my_perpusku/data/models/image_file_model.dart';
import 'package:path/path.dart' as path; // Import path package
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // Pastikan uuid di-import
import '../models/content_model.dart';

class ContentService {
  /// Memastikan direktori 'images' ada di dalam path subject.
  /// Jika tidak ada, maka akan dibuat.
  Future<Directory> ensureImagesDirectoryExists(String subjectPath) async {
    final imagesPath = path.join(subjectPath, 'images');
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
        final fileName = path.basename(entity.path);
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

  /// Menggabungkan konten HTML dengan template index.html untuk ditampilkan.
  Future<String> createMergedHtmlFile(String contentPath) async {
    try {
      final contentFile = File(contentPath);
      final subjectPath = contentFile.parent.path;
      final indexPath = path.join(subjectPath, 'index.html');
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
      final tempFile = File(path.join(tempDir.path, uniqueFileName));
      await tempFile.writeAsString(mergedContent);

      return tempFile.path;
    } catch (e) {
      rethrow;
    }
  }

  /// --- METODE BARU UNTUK MANAJEMEN GAMBAR ---

  /// Menyalin file gambar yang dipilih ke dalam direktori images.
  Future<void> addImage(String subjectPath, File sourceFile) async {
    try {
      final imagesDir = await ensureImagesDirectoryExists(subjectPath);
      final fileName = path.basename(sourceFile.path);
      final destinationPath = path.join(imagesDir.path, fileName);
      final destinationFile = File(destinationPath);

      if (await destinationFile.exists()) {
        throw Exception(
          'Gambar dengan nama "$fileName" sudah ada di galeri ini.',
        );
      }

      await sourceFile.copy(destinationPath);
    } catch (e) {
      // Lempar kembali error untuk ditangani oleh UI
      rethrow;
    }
  }

  /// Mengubah nama file gambar.
  Future<void> renameImage(String oldImagePath, String newImageName) async {
    try {
      if (newImageName.trim().isEmpty) {
        throw Exception("Nama gambar baru tidak boleh kosong.");
      }

      final oldFile = File(oldImagePath);
      if (!await oldFile.exists()) {
        throw Exception(
          "File gambar yang ingin diubah namanya tidak ditemukan.",
        );
      }

      // Sanitasi nama untuk memastikan validitas dan ekstensi tidak hilang
      final extension = path.extension(oldImagePath);
      final sanitizedName = newImageName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
      final newFileName = '$sanitizedName$extension';

      final newPath = path.join(oldFile.parent.path, newFileName);

      if (await File(newPath).exists()) {
        throw Exception("Gambar dengan nama '$newFileName' sudah ada.");
      }

      await oldFile.rename(newPath);
    } catch (e) {
      rethrow;
    }
  }

  /// Menghapus file gambar.
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      } else {
        throw Exception("File gambar yang ingin dihapus tidak ditemukan.");
      }
    } catch (e) {
      rethrow;
    }
  }
}

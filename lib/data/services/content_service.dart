// lib/data/services/content_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:my_perpusku/data/models/image_file_model.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
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

  /// Mengambil daftar file gambar DAN folder dari path yang diberikan.
  Future<List<FileSystemEntity>> getGalleryEntities(
    String directoryPath,
  ) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final List<FileSystemEntity> entities = await directory.list().toList();
    final List<Directory> folders = [];
    final List<File> files = [];

    for (final entity in entities) {
      if (entity is Directory) {
        folders.add(entity);
      } else if (entity is File) {
        final fileName = path.basename(entity.path);
        if ([
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.bmp',
          '.webp',
        ].any((ext) => fileName.toLowerCase().endsWith(ext))) {
          files.add(entity);
        }
      }
    }

    // Urutkan folder dan file secara terpisah, lalu gabungkan
    folders.sort(
      (a, b) => path.basename(a.path).compareTo(path.basename(b.path)),
    );
    files.sort(
      (a, b) => path.basename(a.path).compareTo(path.basename(b.path)),
    );

    return [...folders, ...files];
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

  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      default:
        return 'application/octet-stream';
    }
  }

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

      String mainContent = await contentFile.readAsString();
      final imgRegex = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false);
      final matches = imgRegex.allMatches(mainContent);

      for (final match in matches) {
        final originalSrc = match.group(1);

        if (originalSrc != null &&
            !originalSrc.startsWith('data:') &&
            !originalSrc.startsWith('http')) {
          final absoluteImagePath = path.join(subjectPath, originalSrc);
          final imageFile = File(absoluteImagePath);

          if (await imageFile.exists()) {
            final imageBytes = await imageFile.readAsBytes();
            final base64String = base64Encode(imageBytes);
            final mimeType = _getMimeType(absoluteImagePath);
            final dataUri = 'data:$mimeType;base64,$base64String';
            mainContent = mainContent.replaceFirst(
              'src="$originalSrc"',
              'src="$dataUri"',
            );
          }
        }
      }

      final String indexContent = await indexFile.readAsString();
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

  Future<void> addImage(String directoryPath, File sourceFile) async {
    try {
      final fileName = path.basename(sourceFile.path);
      final destinationPath = path.join(directoryPath, fileName);
      final destinationFile = File(destinationPath);

      if (await destinationFile.exists()) {
        throw Exception(
          'Gambar dengan nama "$fileName" sudah ada di lokasi ini.',
        );
      }

      await sourceFile.copy(destinationPath);
    } catch (e) {
      rethrow;
    }
  }

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

  Future<void> replaceImage(String oldImagePath, File newSourceFile) async {
    try {
      final oldFile = File(oldImagePath);
      if (!await oldFile.exists()) {
        throw Exception("File gambar yang ingin diganti tidak ditemukan.");
      }
      final destinationPath = oldImagePath;
      if (!await newSourceFile.exists()) {
        throw Exception("File gambar baru tidak ditemukan.");
      }
      await newSourceFile.copy(destinationPath);
    } catch (e) {
      rethrow;
    }
  }

  // --- FUNGSI BARU UNTUK MANAJEMEN FOLDER ---
  Future<void> createGalleryFolder(
    String currentPath,
    String folderName,
  ) async {
    if (folderName.trim().isEmpty) {
      throw Exception("Nama folder tidak boleh kosong.");
    }
    final sanitizedName = folderName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final newFolderPath = path.join(currentPath, sanitizedName);
    final directory = Directory(newFolderPath);

    if (await directory.exists()) {
      throw Exception("Folder dengan nama '$sanitizedName' sudah ada.");
    }
    await directory.create();
  }

  Future<void> renameGalleryFolder(
    String oldFolderPath,
    String newFolderName,
  ) async {
    if (newFolderName.trim().isEmpty) {
      throw Exception("Nama folder baru tidak boleh kosong.");
    }
    final oldDirectory = Directory(oldFolderPath);
    if (!await oldDirectory.exists()) {
      throw Exception("Folder yang ingin diubah namanya tidak ditemukan.");
    }
    final sanitizedName = newFolderName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final newFolderPath = path.join(oldDirectory.parent.path, sanitizedName);

    if (await Directory(newFolderPath).exists()) {
      throw Exception("Folder dengan nama '$sanitizedName' sudah ada.");
    }
    await oldDirectory.rename(newFolderPath);
  }

  Future<void> deleteGalleryFolder(String folderPath) async {
    final directory = Directory(folderPath);
    if (!await directory.exists()) {
      throw Exception("Folder yang ingin dihapus tidak ditemukan.");
    }
    await directory.delete(recursive: true);
  }
}

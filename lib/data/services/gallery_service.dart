// lib/data/services/gallery_service.dart

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:my_perpusku/data/models/content_stats_model.dart';

class GalleryService {
  /// Memastikan direktori 'images' ada di dalam path subject.
  Future<Directory> ensureImagesDirectoryExists(String subjectPath) async {
    final imagesPath = path.join(subjectPath, 'images');
    final imagesDir = Directory(imagesPath);
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Menghitung jumlah gambar dan folder di dalam galeri secara rekursif.
  Future<GalleryStats> getGalleryStats(String subjectPath) async {
    final imagesDir = await ensureImagesDirectoryExists(subjectPath);
    int imageCount = 0;
    int folderCount = 0;

    if (!await imagesDir.exists()) {
      return GalleryStats(imageCount: 0, folderCount: 0);
    }

    final Stream<FileSystemEntity> entities = imagesDir.list(recursive: true);
    await for (final entity in entities) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase();
        if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
          imageCount++;
        }
      } else if (entity is Directory) {
        folderCount++;
      }
    }
    return GalleryStats(imageCount: imageCount, folderCount: folderCount);
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

    folders.sort(
      (a, b) => path.basename(a.path).compareTo(path.basename(b.path)),
    );
    files.sort(
      (a, b) => path.basename(a.path).compareTo(path.basename(b.path)),
    );

    return [...folders, ...files];
  }

  /// Mengambil daftar folder dari path galeri yang diberikan.
  Future<List<Directory>> getGalleryFolders(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      return [];
    }
    final List<Directory> folders = [];
    await for (final entity in directory.list()) {
      if (entity is Directory) {
        folders.add(entity);
      }
    }
    folders.sort(
      (a, b) => path.basename(a.path).compareTo(path.basename(b.path)),
    );
    return folders;
  }

  /// Menambah file gambar baru ke galeri.
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

  /// Mengganti file gambar yang ada dengan file baru.
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

  /// Membuat folder baru di dalam galeri.
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

  /// Mengubah nama folder di dalam galeri.
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

  /// Menghapus folder dari galeri secara rekursif.
  Future<void> deleteGalleryFolder(String folderPath) async {
    final directory = Directory(folderPath);
    if (!await directory.exists()) {
      throw Exception("Folder yang ingin dihapus tidak ditemukan.");
    }
    await directory.delete(recursive: true);
  }

  /// Memindahkan file atau folder ke lokasi tujuan.
  Future<void> moveEntity(
    FileSystemEntity entity,
    String destinationPath,
  ) async {
    final destDir = Directory(destinationPath);
    if (!await destDir.exists()) {
      throw Exception("Direktori tujuan tidak ditemukan.");
    }

    final newPath = path.join(destinationPath, path.basename(entity.path));

    if (entity.path == destinationPath) {
      return;
    }

    if (entity is Directory) {
      if (newPath.startsWith(entity.path)) {
        throw Exception(
          "Tidak dapat memindahkan folder ke dalam dirinya sendiri.",
        );
      }
    }

    if (await File(newPath).exists() || await Directory(newPath).exists()) {
      throw Exception(
        'Nama "${path.basename(entity.path)}" sudah ada di folder tujuan.',
      );
    }

    await entity.rename(newPath);
  }
}

// lib/data/services/subject_service.dart

import 'dart:convert';
import 'dart:io';
import '../models/subject_model.dart';
// --- PERUBAHAN DI SINI: IMPORT GALLERY SERVICE ---
import 'gallery_service.dart';

class SubjectService {
  // Metode getSubjects tidak berubah
  Future<List<Subject>> getSubjects(String topicPath) async {
    final directory = Directory(topicPath);

    if (!await directory.exists()) {
      throw Exception(
        'Error: Direktori tidak dapat ditemukan di path:\n$topicPath',
      );
    }

    final List<Subject> subjects = [];
    final Stream<FileSystemEntity> entities = directory.list();

    await for (final entity in entities) {
      if (entity is Directory) {
        final folderName = entity.path.split(Platform.pathSeparator).last;
        subjects.add(Subject(name: folderName));
      }
    }

    subjects.sort((a, b) => a.name.compareTo(b.name));
    return subjects;
  }

  // Metode createSubject diperbarui untuk memanggil GalleryService
  Future<void> createSubject(String topicPath, String subjectName) async {
    if (subjectName.trim().isEmpty) {
      throw Exception("Nama subject tidak boleh kosong.");
    }
    final sanitizedName = subjectName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final newSubjectPath = '$topicPath/$sanitizedName';
    final directory = Directory(newSubjectPath);

    if (await directory.exists()) {
      throw Exception("Subject dengan nama '$sanitizedName' sudah ada.");
    }

    try {
      await directory.create();
      final metadataFile = File('$newSubjectPath/metadata.json');
      final initialMetadata = {"content": []};
      await metadataFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(initialMetadata),
      );
      await ensureIndexFileExists(newSubjectPath);
      // --- PERUBAHAN DI SINI: PANGGIL GALLERY SERVICE ---
      await GalleryService().ensureImagesDirectoryExists(newSubjectPath);
    } catch (e) {
      throw Exception("Gagal membuat subject: $e");
    }
  }

  // Metode renameSubject dan deleteSubject tidak berubah
  Future<void> renameSubject(
    String oldSubjectPath,
    String newSubjectName,
  ) async {
    if (newSubjectName.trim().isEmpty) {
      throw Exception("Nama subject baru tidak boleh kosong.");
    }

    final oldDirectory = Directory(oldSubjectPath);
    if (!await oldDirectory.exists()) {
      throw Exception("Subject yang ingin diubah namanya tidak ditemukan.");
    }

    final sanitizedName = newSubjectName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final newSubjectPath = '${oldDirectory.parent.path}/$sanitizedName';

    if (await Directory(newSubjectPath).exists()) {
      throw Exception("Subject dengan nama '$sanitizedName' sudah ada.");
    }

    try {
      await oldDirectory.rename(newSubjectPath);
    } catch (e) {
      throw Exception("Gagal mengubah nama subject: $e");
    }
  }

  Future<void> deleteSubject(String subjectPath) async {
    final directory = Directory(subjectPath);
    if (!await directory.exists()) {
      throw Exception("Subject yang ingin dihapus tidak ditemukan.");
    }

    try {
      await directory.delete(recursive: true);
    } catch (e) {
      throw Exception("Gagal menghapus subject: $e");
    }
  }

  Future<void> ensureIndexFileExists(String subjectPath) async {
    try {
      final indexFile = File('$subjectPath/index.html');

      if (!await indexFile.exists()) {
        await indexFile.writeAsString('''
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Konten Gabungan</title>
    <style>
      body { font-family: sans-serif; line-height: 1.6; padding: 20px; }
      #main-container { max-width: 800px; margin: auto; }
    </style>
</head>
<body>
    <div id="main-container"></div>
</body>
</html>
''');
      }
    } catch (e) {
      throw Exception('Gagal memastikan keberadaan file index.html: $e');
    }
  }
}

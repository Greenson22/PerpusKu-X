// lib/data/services/subject_service.dart

import 'dart:convert';
import 'dart:io';
import '../models/subject_model.dart';

class SubjectService {
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

  /// Membuat sebuah subject baru (folder baru) di dalam topic.
  Future<void> createSubject(String topicPath, String subjectName) async {
    if (subjectName.trim().isEmpty) {
      throw Exception("Nama subject tidak boleh kosong.");
    }
    // Sanitasi nama folder untuk menghindari karakter yang tidak valid
    final sanitizedName = subjectName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final newSubjectPath = '$topicPath/$sanitizedName';
    final directory = Directory(newSubjectPath);

    if (await directory.exists()) {
      throw Exception("Subject dengan nama '$sanitizedName' sudah ada.");
    }

    try {
      // Buat folder untuk subject
      await directory.create();
      // Buat file metadata.json di dalamnya
      final metadataFile = File('$newSubjectPath/metadata.json');
      final initialMetadata = {"content": []};
      await metadataFile.writeAsString(
        JsonEncoder.withIndent('  ').convert(initialMetadata),
      );
    } catch (e) {
      throw Exception("Gagal membuat subject: $e");
    }
  }

  /// Mengubah nama sebuah subject (folder).
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

    // Sanitasi nama folder baru
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

  /// Menghapus sebuah subject (folder) secara rekursif.
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
}

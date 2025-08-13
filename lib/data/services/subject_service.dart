// lib/data/services/subject_service.dart

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
}

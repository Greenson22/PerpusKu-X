// data/services/topic_service.dart

import 'dart:io';
import '../models/topic_model.dart';

class TopicService {
  // HAPUS PATH HARDCODED DARI SINI
  // static const String _topicsPath = '...';

  /// Mengambil daftar subdirektori dari path yang diberikan.
  Future<List<Topic>> getTopics(String rootPath) async {
    // MODIFIKASI: Tambahkan parameter
    // Validasi apakah path kosong atau tidak
    if (rootPath.isEmpty) {
      throw Exception('Error: Path folder utama belum ditentukan.');
    }

    final directory = Directory(rootPath);

    if (!await directory.exists()) {
      throw Exception(
        'Error: Direktori tidak dapat ditemukan di path:\n$rootPath',
      );
    }

    final List<Topic> topics = [];
    final Stream<FileSystemEntity> entities = directory.list();

    await for (final entity in entities) {
      if (entity is Directory) {
        final folderName = entity.path.split(Platform.pathSeparator).last;
        topics.add(Topic(name: folderName));
      }
    }

    topics.sort((a, b) => a.name.compareTo(b.name));
    return topics;
  }
}

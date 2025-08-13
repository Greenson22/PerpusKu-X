// data/services/topic_service.dart

import 'dart:io';
import '../models/topic_model.dart';

/// Service untuk menangani semua operasi terkait data topics.
/// Memisahkan logika ini dari UI membuatnya mudah diuji dan digunakan kembali.
class TopicService {
  // Path direktori topics yang dituju (hardcoded).
  static const String _topicsPath =
      '/home/lemon-manis-22/RikalG22/PerpusKu/data/file_contents/topics';

  /// Mengambil daftar subdirektori dari path `_topicsPath`.
  ///
  /// Mengembalikan `List<Topic>`.
  /// Melemparkan `Exception` jika direktori tidak ditemukan.
  Future<List<Topic>> getTopics() async {
    final directory = Directory(_topicsPath);

    // Validasi: pastikan direktori ada sebelum mencoba membacanya.
    if (!await directory.exists()) {
      throw Exception(
        'Error: Direktori tidak dapat ditemukan di path:\n$_topicsPath',
      );
    }

    final List<Topic> topics = [];
    final Stream<FileSystemEntity> entities = directory.list();

    await for (final entity in entities) {
      // Filter hanya untuk entitas yang merupakan sebuah direktori.
      if (entity is Directory) {
        final folderName = entity.path.split(Platform.pathSeparator).last;
        topics.add(Topic(name: folderName));
      }
    }

    // Urutkan hasil berdasarkan abjad untuk tampilan yang konsisten.
    topics.sort((a, b) => a.name.compareTo(b.name));
    return topics;
  }
}

// lib/data/services/topic_service.dart

import 'dart:io';
import '../models/topic_model.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class TopicService {
  /// Mengambil daftar subdirektori dari path yang diberikan.
  Future<List<Topic>> getTopics(String rootPath) async {
    // Validasi apakah path kosong atau tidak
    if (rootPath.isEmpty) {
      throw Exception('Error: Path folder utama belum ditentukan.');
    }

    final directory = Directory(rootPath);

    if (!await directory.exists()) {
      // Jika direktori utama tidak ada, buatlah.
      await directory.create(recursive: true);
      debugPrint('Direktori topics dibuat di: $rootPath');
      return []; // Kembalikan list kosong karena baru dibuat
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

  /// Membuat sebuah topic baru (folder baru).
  Future<void> createTopic(String rootPath, String topicName) async {
    if (topicName.trim().isEmpty) {
      throw Exception("Nama topic tidak boleh kosong.");
    }
    // Sanitasi nama folder untuk menghindari karakter yang tidak valid
    final sanitizedName = topicName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final newTopicPath = '$rootPath/$sanitizedName';
    final directory = Directory(newTopicPath);

    if (await directory.exists()) {
      throw Exception("Topic dengan nama '$sanitizedName' sudah ada.");
    }

    try {
      await directory.create();
    } catch (e) {
      throw Exception("Gagal membuat folder topic: $e");
    }
  }

  /// Mengubah nama sebuah topic (folder).
  Future<void> renameTopic(String oldTopicPath, String newTopicName) async {
    if (newTopicName.trim().isEmpty) {
      throw Exception("Nama topic baru tidak boleh kosong.");
    }

    final oldDirectory = Directory(oldTopicPath);
    if (!await oldDirectory.exists()) {
      throw Exception("Topic yang ingin diubah namanya tidak ditemukan.");
    }

    // Sanitasi nama folder baru
    final sanitizedName = newTopicName.replaceAll(RegExp(r'[^\w\s\.-]'), '_');
    final newTopicPath = '${oldDirectory.parent.path}/$sanitizedName';

    if (await Directory(newTopicPath).exists()) {
      throw Exception("Topic dengan nama '$sanitizedName' sudah ada.");
    }

    try {
      await oldDirectory.rename(newTopicPath);
    } catch (e) {
      throw Exception("Gagal mengubah nama topic: $e");
    }
  }

  /// Menghapus sebuah topic (folder) secara rekursif.
  Future<void> deleteTopic(String topicPath) async {
    final directory = Directory(topicPath);
    if (!await directory.exists()) {
      throw Exception("Topic yang ingin dihapus tidak ditemukan.");
    }

    try {
      await directory.delete(recursive: true);
    } catch (e) {
      throw Exception("Gagal menghapus topic: $e");
    }
  }
}

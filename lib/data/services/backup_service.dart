// lib/data/services/backup_service.dart

import 'dart:io';
import 'package:archive/archive_io.dart';

class BackupService {
  /// Membuat backup dari folder sumber dan menyimpannya sebagai file ZIP
  /// di lokasi yang ditentukan.
  ///
  /// - `sourceDataPath`: Path lengkap ke folder 'data' yang akan di-backup.
  /// - `outputZipPath`: Path lengkap (termasuk nama file) tempat file ZIP akan disimpan.
  Future<void> createBackup(String sourceDataPath, String outputZipPath) async {
    final sourceDir = Directory(sourceDataPath);
    if (!await sourceDir.exists()) {
      throw Exception('Folder "data" tidak ditemukan di path yang diberikan.');
    }

    try {
      // Buat file ZIP dari direktori
      final encoder = ZipFileEncoder();
      encoder.create(outputZipPath);
      // Menambahkan folder 'data' ke dalam zip
      await encoder.addDirectory(sourceDir, includeDirName: true);
      encoder.close();
    } catch (e) {
      // Lempar kembali error untuk ditangani oleh UI
      rethrow;
    }
  }
}

// lib/data/services/backup_service.dart

import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class BackupService {
  /// Membuat backup dari folder 'PerpusKu' dan menyimpannya sebagai file ZIP
  /// di folder Downloads.
  Future<String> createBackup(String perpusKuPath) async {
    final sourceDir = Directory(perpusKuPath);
    if (!await sourceDir.exists()) {
      throw Exception(
        'Folder "PerpusKu" tidak ditemukan di path yang diberikan.',
      );
    }

    try {
      // Tentukan lokasi penyimpanan file backup
      final Directory? downloadDir = await getDownloadsDirectory();
      if (downloadDir == null) {
        throw Exception("Tidak dapat menemukan direktori Downloads.");
      }

      final backupDir = Directory('${downloadDir.path}/PerpusKu Backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Buat nama file yang unik dengan timestamp
      final timestamp = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now());
      final zipFilePath = '${backupDir.path}/perpusku_backup_$timestamp.zip';

      // Buat file ZIP dari direktori
      final encoder = ZipFileEncoder();
      encoder.create(zipFilePath);
      await encoder.addDirectory(sourceDir, includeDirName: true);
      encoder.close();

      return zipFilePath; // Kembalikan path file ZIP yang berhasil dibuat
    } catch (e) {
      // Lempar kembali error untuk ditangani oleh UI
      rethrow;
    }
  }
}

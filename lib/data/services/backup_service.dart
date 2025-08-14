// lib/data/services/backup_service.dart

import 'dart:io';
import 'package:archive/archive_io.dart';

class BackupService {
  // Metode createBackup tidak berubah...
  Future<void> createBackup(String sourceDataPath, String outputZipPath) async {
    final sourceDir = Directory(sourceDataPath);
    if (!await sourceDir.exists()) {
      throw Exception('Folder "data" tidak ditemukan di path yang diberikan.');
    }

    try {
      final encoder = ZipFileEncoder();
      encoder.create(outputZipPath);
      await encoder.addDirectory(sourceDir, includeDirName: true);
      encoder.close();
    } catch (e) {
      rethrow;
    }
  }

  /// Mengimpor data dari file backup ZIP.
  /// Operasi ini akan menghapus folder 'data' yang ada sebelum mengekstrak.
  Future<void> importBackup(String zipFilePath, String perpusKuPath) async {
    final zipFile = File(zipFilePath);
    if (!await zipFile.exists()) {
      throw Exception('File backup ZIP tidak ditemukan.');
    }

    final perpusKuDir = Directory(perpusKuPath);
    final dataDir = Directory('$perpusKuPath/data');

    try {
      // 1. Hapus folder 'data' yang lama jika ada
      if (await dataDir.exists()) {
        await dataDir.delete(recursive: true);
      }

      // 2. Ekstrak file ZIP ke folder 'PerpusKu'
      // --- BAGIAN YANG DIPERBAIKI ---
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      // --- AKHIR BAGIAN YANG DIPERBAIKI ---

      extractArchiveToDisk(archive, perpusKuPath);
    } catch (e) {
      // Lempar kembali error untuk ditangani oleh UI
      rethrow;
    }
  }
}

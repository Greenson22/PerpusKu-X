// lib/data/services/html_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class HtmlService {
  /// Mendapatkan tipe MIME dari sebuah file gambar berdasarkan ekstensinya.
  String _getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      default:
        return 'application/octet-stream';
    }
  }

  /// Membuat file HTML gabungan sementara untuk ditampilkan.
  /// Gambar lokal akan di-embed sebagai Base64.
  Future<String> createMergedHtmlFile(String contentPath) async {
    try {
      final contentFile = File(contentPath);
      final subjectPath = contentFile.parent.path;
      final indexPath = path.join(subjectPath, 'index.html');
      final indexFile = File(indexPath);

      if (!await indexFile.exists()) {
        throw Exception(
          'File "index.html" tidak ditemukan di folder subject: $subjectPath',
        );
      }
      if (!await contentFile.exists()) {
        throw Exception('File konten tidak ditemukan: $contentPath');
      }

      String mainContent = await contentFile.readAsString();
      final imgRegex = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false);
      final matches = imgRegex.allMatches(mainContent);

      for (final match in matches) {
        final originalSrc = match.group(1);

        if (originalSrc != null &&
            !originalSrc.startsWith('data:') &&
            !originalSrc.startsWith('http')) {
          final absoluteImagePath = path.join(subjectPath, originalSrc);
          final imageFile = File(absoluteImagePath);

          if (await imageFile.exists()) {
            final imageBytes = await imageFile.readAsBytes();
            final base64String = base64Encode(imageBytes);
            final mimeType = _getMimeType(absoluteImagePath);
            final dataUri = 'data:$mimeType;base64,$base64String';
            mainContent = mainContent.replaceFirst(
              'src="$originalSrc"',
              'src="$dataUri"',
            );
          }
        }
      }

      final String indexContent = await indexFile.readAsString();
      final mergedContent = indexContent.replaceFirst(
        RegExp(r'<div[^>]*id="main-container"[^>]*>[\s\S]*?</div>'),
        '<div id="main-container">$mainContent</div>',
      );

      final tempDir = await getTemporaryDirectory();
      final uniqueFileName = '${const Uuid().v4()}.html';
      final tempFile = File(path.join(tempDir.path, uniqueFileName));
      await tempFile.writeAsString(mergedContent);

      return tempFile.path;
    } catch (e) {
      rethrow;
    }
  }
}

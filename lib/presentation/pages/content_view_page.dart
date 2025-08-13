// lib/presentation/pages/content_view_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart'; // 1. Import flutter_html

// 2. Ubah menjadi StatelessWidget karena tidak perlu state kompleks
class ContentViewPage extends StatelessWidget {
  final String contentPath;
  final String contentName;

  const ContentViewPage({
    super.key,
    required this.contentPath,
    required this.contentName,
  });

  // Fungsi untuk membaca konten file HTML secara sinkron
  String _getHtmlContent() {
    try {
      final file = File(contentPath);
      if (file.existsSync()) {
        return file.readAsStringSync();
      } else {
        // Mengembalikan HTML error jika file tidak ditemukan
        return '<h2>File tidak ditemukan</h2><p>File tidak dapat ditemukan di path: $contentPath</p>';
      }
    } catch (e) {
      // Mengembalikan HTML error jika terjadi kesalahan lain
      return '<h2>Gagal memuat konten</h2><p>Terjadi kesalahan: $e</p>';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contentName)),
      // 3. Gunakan SingleChildScrollView dan Html widget
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Html(
          data: _getHtmlContent(), // Baca konten dari file
          style: {
            // Styling dasar agar konten lebih mudah dibaca
            "body": Style(
              fontSize: FontSize.medium,
              lineHeight: LineHeight.normal,
            ),
            "h1": Style(fontSize: FontSize.xxLarge),
            "h2": Style(fontSize: FontSize.xLarge),
          },
        ),
      ),
    );
  }
}

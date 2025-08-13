// lib/presentation/pages/content_view_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ContentViewPage extends StatefulWidget {
  final String contentPath;
  final String contentName;

  const ContentViewPage({
    super.key,
    required this.contentPath,
    required this.contentName,
  });

  @override
  State<ContentViewPage> createState() => _ContentViewPageState();
}

class _ContentViewPageState extends State<ContentViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHtmlContent();
  }

  Future<void> _loadHtmlContent() async {
    try {
      final file = File(widget.contentPath);
      if (await file.exists()) {
        final htmlString = await file.readAsString();
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {
                setState(() {
                  _isLoading = false;
                });
              },
              onWebResourceError: (error) {
                setState(() {
                  _error = 'Error loading page: ${error.description}';
                  _isLoading = false;
                });
              },
            ),
          )
          ..loadHtmlString(htmlString);
      } else {
        setState(() {
          _error = 'File tidak ditemukan di:\n${widget.contentPath}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat konten: $e';
        _isLoading = false;
      });
    }
    // Pastikan untuk memanggil setState setelah inisialisasi controller
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.contentName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}

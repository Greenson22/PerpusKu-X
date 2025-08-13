// lib/presentation/pages/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/directory_provider.dart';
import 'topics_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _pickDirectory(WidgetRef ref) async {
    // Menggunakan file_picker untuk memilih direktori
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder Utama "topics"',
    );

    if (selectedDirectory != null) {
      // Update state provider dengan path yang baru dipilih
      ref.read(rootDirectoryProvider.notifier).state = selectedDirectory;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pantau path direktori yang sedang aktif
    final rootPath = ref.watch(rootDirectoryProvider);
    final bool isPathSelected = rootPath != null && rootPath.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard PerpusKu')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tombol untuk memilih folder utama
              FilledButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('Pilih Folder Utama'),
                onPressed: () => _pickDirectory(ref),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              // Menampilkan path yang dipilih
              if (isPathSelected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Folder aktif:\n$rootPath',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              const Divider(height: 40),

              // Tombol untuk navigasi ke halaman Topics
              // Tombol ini hanya aktif jika folder sudah dipilih
              OutlinedButton.icon(
                icon: const Icon(Icons.topic_outlined),
                label: const Text('Lihat Topics'),
                onPressed: isPathSelected
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TopicsPage(),
                          ),
                        );
                      }
                    : null, // Tombol non-aktif jika path belum dipilih
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (!isPathSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Silakan pilih folder utama terlebih dahulu untuk melihat topics.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/presentation/pages/dashboard_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/directory_provider.dart';
import 'topics_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _setupDirectory(BuildContext context, WidgetRef ref) async {
    // 1. Minta pengguna memilih LOKASI untuk menempatkan folder PerpusKu
    String? selectedLocation = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Lokasi untuk Menyimpan Folder "PerpusKu"',
    );

    // Jika pengguna tidak membatalkan
    if (selectedLocation != null) {
      try {
        final path = Platform.pathSeparator;

        // 2. Buat path untuk folder "PerpusKu" dan struktur di dalamnya
        final perpusKuPath = '$selectedLocation${path}PerpusKu';
        final topicsPath =
            '$perpusKuPath${path}data${path}file_contents${path}topics';

        final topicsDir = Directory(topicsPath);

        // Cek apakah folder 'PerpusKu' sudah ada di lokasi itu
        final perpusKuDir = Directory(perpusKuPath);
        final bool perpusKuExists = await perpusKuDir.exists();

        // 3. Buat direktori. `recursive: true` akan membuat semua folder
        //    (PerpusKu, data, file_contents, topics) jika belum ada.
        await topicsDir.create(recursive: true);

        // Beri tahu pengguna bahwa folder telah dibuat (jika sebelumnya tidak ada)
        if (!perpusKuExists && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Folder "PerpusKu" berhasil dibuat di: $selectedLocation',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // 4. Simpan path LENGKAP ke 'topics' di provider, lalu tampilkan
        ref.read(rootDirectoryProvider.notifier).state = topicsPath;
      } catch (e) {
        // Tangani jika ada error (misal: masalah izin/permission)
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal membuat struktur folder: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // 5. Ubah teks tombol agar lebih jelas
              FilledButton.icon(
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Pilih Lokasi & Buat Folder'),
                onPressed: () => _setupDirectory(context, ref),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              if (isPathSelected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Folder Topics Aktif:\n$rootPath',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              const Divider(height: 40),
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
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (!isPathSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Silakan pilih lokasi untuk membuat folder "PerpusKu".',
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

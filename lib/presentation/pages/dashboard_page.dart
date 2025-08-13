// lib/presentation/pages/dashboard_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 1. Import package
import '../providers/directory_provider.dart';
import 'topics_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  // Ganti fungsi ini
  Future<void> _setupDirectory(BuildContext context, WidgetRef ref) async {
    try {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }

      if (!status.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Izin akses penyimpanan eksternal ditolak. Fitur tidak dapat dilanjutkan.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      String? selectedLocation = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Pilih Lokasi untuk Menyimpan Folder "PerpusKu"',
      );

      if (selectedLocation != null) {
        final path = Platform.pathSeparator;
        final perpusKuPath = '$selectedLocation${path}PerpusKu';
        final topicsPath =
            '$perpusKuPath${path}data${path}file_contents${path}topics';
        final topicsDir = Directory(topicsPath);
        final perpusKuDir = Directory(perpusKuPath);
        final bool perpusKuExists = await perpusKuDir.exists();

        await topicsDir.create(recursive: true);

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

        // Simpan path ke provider
        ref.read(rootDirectoryProvider.notifier).state = topicsPath;

        // 2. SIMPAN PATH KE SHARED PREFERENCES
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('root_directory_path', topicsPath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Bagian @override Widget build(BuildContext context, WidgetRef ref) ...
  // tidak perlu diubah.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... (Bagian build tidak berubah)
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
              if (isPathSelected)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'Folder Topics Aktif:\n$rootPath',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
                children: [
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
                  FilledButton.icon(
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: const Text('Pilih Lokasi'),
                    onPressed: () => _setupDirectory(context, ref),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
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

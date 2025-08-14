// lib/presentation/pages/dashboard_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_perpusku/data/services/backup_service.dart';
import 'package:my_perpusku/presentation/widgets/animated_book.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/directory_provider.dart';
import 'topics_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _setupDirectory(BuildContext context, WidgetRef ref) async {
    // ... (fungsi _setupDirectory tidak berubah) ...
    try {
      if (Platform.isAndroid) {
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

        await topicsDir.create(recursive: true);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Folder "PerpusKu" berhasil diinisialisasi di: $selectedLocation',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        ref.read(rootDirectoryProvider.notifier).state = topicsPath;

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

  // --- FUNGSI BACKUP YANG DIPERBARUI ---
  Future<void> _createBackup(BuildContext context, WidgetRef ref) async {
    final rootPath = ref.read(rootDirectoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (rootPath == null || rootPath.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Lokasi folder utama belum diatur. Tidak dapat membuat backup.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // 1. Minta pengguna memilih lokasi dan nama file untuk menyimpan backup
      final timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Pilih Lokasi Penyimpanan Backup',
        fileName: 'perpusku_backup_$timestamp.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      // Jika pengguna membatalkan dialog penyimpanan file
      if (outputFile == null) {
        return;
      }

      // Tampilkan dialog loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 2. Tentukan path folder 'data' yang akan di-backup
      // rootPath = .../PerpusKu/data/file_contents/topics
      // Kita perlu naik 2 level untuk mendapatkan folder 'data'
      final dataPath = Directory(rootPath).parent.parent.path;

      final backupService = BackupService();
      await backupService.createBackup(dataPath, outputFile);

      navigator.pop(); // Tutup dialog loading

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Backup folder "data" berhasil disimpan di: $outputFile',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (navigator.canPop()) {
        navigator.pop(); // Tutup dialog loading jika masih terbuka
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal membuat backup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ------------------------------------------

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootPath = ref.watch(rootDirectoryProvider);
    final bool isPathSelected = rootPath != null && rootPath.isNotEmpty;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard PerpusKu'), elevation: 1),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: 100, height: 100, child: AnimatedBook()),
              const SizedBox(height: 24),
              Text(
                'Selamat Datang!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Atur dan kelola semua topik serta materi Anda dengan mudah.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              _DashboardCard(
                icon: Icons.topic_outlined,
                iconColor: Colors.purple,
                title: 'Topik Saya',
                subtitle: 'Akses semua topik dan subjek yang telah Anda buat.',
                isEnabled: isPathSelected,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TopicsPage()),
                  );
                },
              ),
              const SizedBox(height: 16),
              _DashboardCard(
                icon: Icons.folder_open_outlined,
                iconColor: Colors.orange,
                title: 'Pengaturan Lokasi',
                subtitle:
                    'Pilih atau ubah folder utama untuk menyimpan semua data.',
                onTap: () => _setupDirectory(context, ref),
              ),
              const SizedBox(height: 16),
              _DashboardCard(
                icon: Icons.backup_outlined,
                iconColor: Colors.blue,
                title: 'Buat Backup Data',
                subtitle: 'Cadangkan folder "data" Anda ke dalam file ZIP.',
                isEnabled: isPathSelected,
                onTap: () => _createBackup(context, ref),
              ),
              const SizedBox(height: 24),
              if (isPathSelected)
                Card(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          'Lokasi Folder Aktif:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rootPath ?? '',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Silakan pilih lokasi folder "PerpusKu" terlebih dahulu untuk memulai.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget Kustom untuk Kartu Dashboard
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isEnabled;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isEnabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias, // Agar efek splash tidak keluar dari card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: isEnabled ? iconColor : Colors.grey.shade400,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? null : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnabled)
                const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

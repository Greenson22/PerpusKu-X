// lib/presentation/pages/dashboard_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_perpusku/presentation/pages/about_page.dart';
import 'package:my_perpusku/presentation/widgets/dashboard/dashboard_card.dart';
import 'package:my_perpusku/presentation/providers/theme_provider.dart';
import 'package:my_perpusku/presentation/widgets/animated_book.dart';
import 'package:my_perpusku/presentation/widgets/dashboard/animation_settings_dialog.dart';
import 'package:my_perpusku/presentation/widgets/matrix_rain.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/all_content_provider.dart';
import '../providers/directory_provider.dart';
import 'topics_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  /// Menampilkan dialog untuk mengatur animasi.
  void _showAnimationSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AnimationSettingsDialog(),
    );
  }

  Future<void> _setupDirectory(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootPath = ref.watch(rootDirectoryProvider);
    final isPathSelected = rootPath != null && rootPath.isNotEmpty;
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeProvider);
    final allTitlesAsync = ref.watch(allContentTitlesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard PerpusKu'),
        elevation: 1,
        actions: [
          if (themeMode == ThemeMode.dark)
            IconButton(
              icon: const Icon(Icons.tune_outlined),
              tooltip: 'Pengaturan Animasi',
              onPressed: () => _showAnimationSettingsDialog(context),
            ),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Ubah Tema',
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang Aplikasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (themeMode == ThemeMode.dark)
            Positioned.fill(
              child: allTitlesAsync.when(
                data: (titles) => MatrixRain(words: titles),
                loading: () => const MatrixRain(words: []),
                error: (err, stack) => const MatrixRain(words: []),
              ),
            ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    width: 100,
                    height: 100,
                    child: AnimatedBook(),
                  ),
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
                  DashboardCard(
                    icon: Icons.topic_outlined,
                    iconColor: Colors.purple,
                    title: 'Topik Saya',
                    subtitle:
                        'Akses semua topik dan subjek yang telah Anda buat.',
                    isEnabled: isPathSelected,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TopicsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DashboardCard(
                    icon: Icons.folder_open_outlined,
                    iconColor: Colors.orange,
                    title: 'Pengaturan Lokasi',
                    subtitle:
                        'Pilih atau ubah folder utama untuk menyimpan semua data.',
                    onTap: () => _setupDirectory(context, ref),
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
        ],
      ),
    );
  }
}

// lib/presentation/pages/about_page.dart

import 'package:flutter/material.dart';
import 'package:my_perpusku/presentation/widgets/waving_flag.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tentang Aplikasi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  // --- PERUBAHAN DI SINI: DARI ICON MENJADI LOGO ---
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      // Pastikan Anda sudah meletakkan logo di path ini
                      // dan mendaftarkannya di pubspec.yaml
                      child: Image.asset(
                        'assets/icon/icon.png',
                        fit: BoxFit.cover,
                        // Tambahkan error builder untuk menangani jika file tidak ada
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.school_outlined,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // --- AKHIR PERUBAHAN ---
                  const SizedBox(height: 16),
                  Text(
                    'PerpusKu',
                    style: textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manajemen Konten Pribadi Anda',
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Deskripsi Aplikasi
            _buildSectionTitle(context, 'Tentang Aplikasi'),
            const SizedBox(height: 8),
            const Text(
              'PerpusKu adalah aplikasi manajemen konten pribadi yang dirancang untuk membantu Anda mengatur materi, catatan, dan pengetahuan secara terstruktur dan mudah diakses. Dibuat dengan Flutter, aplikasi ini menawarkan solusi yang andal untuk mengelola informasi penting Anda langsung di perangkat, memberikan kontrol penuh atas data tanpa ketergantungan pada layanan cloud.',
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Fitur Utama
            _buildSectionTitle(context, 'Fitur Utama'),
            const SizedBox(height: 8),
            const _FeatureTile(
              icon: Icons.folder_copy_outlined,
              title: 'Struktur Topik & Subjek',
              subtitle: 'Buat, ubah, dan hapus kategori materi dengan mudah.',
            ),
            const _FeatureTile(
              icon: Icons.edit_document,
              title: 'Manajemen Konten HTML',
              subtitle:
                  'Tulis catatan dalam format HTML untuk pemformatan yang kaya.',
            ),
            const _FeatureTile(
              icon: Icons.photo_library_outlined,
              title: 'Galeri Gambar',
              subtitle: 'Lengkapi catatan Anda dengan gambar pendukung.',
            ),
            const _FeatureTile(
              icon: Icons.backup_outlined,
              title: 'Backup & Impor Lokal',
              subtitle: 'Amankan dan pulihkan data Anda dengan mudah.',
            ),
            const Divider(height: 48),

            // Informasi Pengembang
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.deepPurple,
                    child: Icon(
                      Icons.person_outline,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Dibuat oleh:', style: textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Frendy Rikal Gerung, S.Kom.',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sarjana Komputer dari Universitas Negeri Manado',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Menambahkan widget bendera yang sudah ada
                  SizedBox(
                    width: 80,
                    height: 50,
                    child: WavingFlag(), //
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(0),
      leading: Icon(icon, color: Colors.deepPurple.shade300, size: 32),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }
}

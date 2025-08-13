// lib/presentation/providers/directory_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// StateProvider untuk menyimpan path direktori utama yang dipilih oleh pengguna.
///
/// Nilai awalnya adalah null, menandakan belum ada direktori yang dipilih.
final rootDirectoryProvider = StateProvider<String?>((ref) => null);

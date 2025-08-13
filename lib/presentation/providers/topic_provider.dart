// presentation/providers/topic_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/topic_model.dart';
import '../../data/services/topic_service.dart';
import 'directory_provider.dart'; // IMPORT provider direktori

final topicServiceProvider = Provider<TopicService>((ref) {
  return TopicService();
});

// MODIFIKASI: Ubah menjadi FutureProvider biasa yang bergantung pada provider lain
final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final topicService = ref.watch(topicServiceProvider);
  // Ambil path dari rootDirectoryProvider
  final rootPath = ref.watch(rootDirectoryProvider);

  // Jika path belum dipilih, kembalikan list kosong atau throw error
  if (rootPath == null || rootPath.isEmpty) {
    // Mengembalikan list kosong agar UI tidak menampilkan error, tapi pesan "kosong"
    return [];
  }

  // Panggil service dengan path yang dinamis
  return topicService.getTopics(rootPath);
});

// presentation/providers/topic_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/topic_model.dart';
import '../../data/services/topic_service.dart';

// 1. Provider untuk instance TopicService.
// Ini memungkinkan kita untuk menukar implementasi service jika diperlukan (misal untuk testing).
final topicServiceProvider = Provider<TopicService>((ref) {
  return TopicService();
});

// 2. FutureProvider untuk mengambil data topics secara asinkron.
// Riverpod akan secara otomatis mengelola state (loading, data, error) untuk kita.
final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  // Membaca (watch) topicServiceProvider untuk mendapatkan instance service.
  final topicService = ref.watch(topicServiceProvider);
  // Memanggil metode dari service untuk mendapatkan data.
  return topicService.getTopics();
});

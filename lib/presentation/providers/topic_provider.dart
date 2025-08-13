// presentation/providers/topic_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/topic_model.dart';
import '../../data/services/topic_service.dart';
import 'directory_provider.dart';

final topicServiceProvider = Provider<TopicService>((ref) {
  return TopicService();
});

final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  final topicService = ref.watch(topicServiceProvider);
  final rootPath = ref.watch(rootDirectoryProvider);

  if (rootPath == null || rootPath.isEmpty) {
    return [];
  }

  return topicService.getTopics(rootPath);
});

// 1. Tambahkan provider baru untuk menangani aksi/mutasi (Create, Update, Delete)
final topicMutationProvider = Provider((ref) {
  final topicService = ref.watch(topicServiceProvider);
  final rootPath = ref.watch(rootDirectoryProvider);

  return TopicMutation(
    topicService: topicService,
    ref: ref,
    rootPath: rootPath,
  );
});

class TopicMutation {
  final TopicService topicService;
  final String? rootPath;
  final Ref ref;

  TopicMutation({
    required this.topicService,
    required this.ref,
    required this.rootPath,
  });

  // Method untuk memicu pembuatan topic
  Future<void> createTopic(String topicName) async {
    if (rootPath == null) throw Exception("Root path belum diatur.");
    await topicService.createTopic(rootPath!, topicName);
    // Refresh/invalidate provider agar UI mengambil data terbaru
    ref.invalidate(topicsProvider);
  }

  // Method untuk memicu pengubahan nama topic
  Future<void> renameTopic(String oldTopicPath, String newTopicName) async {
    await topicService.renameTopic(oldTopicPath, newTopicName);
    ref.invalidate(topicsProvider);
  }

  // Method untuk memicu penghapusan topic
  Future<void> deleteTopic(String topicPath) async {
    await topicService.deleteTopic(topicPath);
    ref.invalidate(topicsProvider);
  }
}

// lib/presentation/widgets/dashboard/topic_filter_list.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_perpusku/presentation/providers/topic_filter_provider.dart';
import 'package:my_perpusku/presentation/providers/topic_provider.dart';

class TopicFilterList extends ConsumerWidget {
  const TopicFilterList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider);
    final filterNotifier = ref.read(topicFilterProvider.notifier);
    final currentFilter = ref.watch(topicFilterProvider);
    final isAllSelected = currentFilter.contains(allTopicsKey);

    return topicsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Text('Gagal memuat topik.'),
      data: (topics) {
        if (topics.isEmpty) {
          return const Text('Tidak ada topik untuk ditampilkan.');
        }
        return Column(
          children: [
            CheckboxListTile(
              title: const Text(
                'Semua Topik',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              value: isAllSelected,
              onChanged: (bool? value) {
                if (value == true && !isAllSelected) {
                  filterNotifier.selectAllTopics();
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ...topics.map((topic) {
              return CheckboxListTile(
                title: Text(topic.name),
                value: !isAllSelected && currentFilter.contains(topic.name),
                onChanged: (bool? value) {
                  filterNotifier.toggleTopic(topic.name);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        );
      },
    );
  }
}

// lib/presentation/pages/subjects_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subject_provider.dart';

class SubjectsPage extends ConsumerWidget {
  final String topicName;
  final String topicPath;

  const SubjectsPage({
    super.key,
    required this.topicName,
    required this.topicPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsyncValue = ref.watch(subjectsProvider(topicPath));

    return Scaffold(
      appBar: AppBar(title: Text(topicName)),
      body: subjectsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return const Center(
              child: Text('Tidak ada subject yang ditemukan.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    Icons.article_outlined,
                    color: Colors.orange.shade300,
                  ),
                  title: Text(subject.name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

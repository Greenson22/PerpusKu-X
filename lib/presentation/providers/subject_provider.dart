// lib/presentation/providers/subject_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/subject_model.dart';
import '../../data/services/subject_service.dart';

final subjectServiceProvider = Provider<SubjectService>((ref) {
  return SubjectService();
});

final subjectsProvider = FutureProvider.family<List<Subject>, String>((
  ref,
  topicPath,
) async {
  final subjectService = ref.watch(subjectServiceProvider);
  return subjectService.getSubjects(topicPath);
});

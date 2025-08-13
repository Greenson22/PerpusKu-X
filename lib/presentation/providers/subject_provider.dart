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

// 1. Tambahkan provider baru untuk menangani aksi/mutasi
final subjectMutationProvider = Provider.family<SubjectMutation, String>((
  ref,
  topicPath,
) {
  final subjectService = ref.watch(subjectServiceProvider);
  return SubjectMutation(
    subjectService: subjectService,
    ref: ref,
    topicPath: topicPath,
  );
});

class SubjectMutation {
  final SubjectService subjectService;
  final String topicPath;
  final Ref ref;

  SubjectMutation({
    required this.subjectService,
    required this.ref,
    required this.topicPath,
  });

  // Method untuk memicu pembuatan subject
  Future<void> createSubject(String subjectName) async {
    await subjectService.createSubject(topicPath, subjectName);
    // Refresh/invalidate provider agar UI mengambil data terbaru
    ref.invalidate(subjectsProvider(topicPath));
  }

  // Method untuk memicu pengubahan nama subject
  Future<void> renameSubject(
    String oldSubjectPath,
    String newSubjectName,
  ) async {
    await subjectService.renameSubject(oldSubjectPath, newSubjectName);
    ref.invalidate(subjectsProvider(topicPath));
  }

  // Method untuk memicu penghapusan subject
  Future<void> deleteSubject(String subjectPath) async {
    await subjectService.deleteSubject(subjectPath);
    ref.invalidate(subjectsProvider(topicPath));
  }
}

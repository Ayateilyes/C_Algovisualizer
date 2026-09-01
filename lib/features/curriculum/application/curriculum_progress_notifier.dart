import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/curriculum_data.dart';

/// Key used to store lesson completion data in SharedPreferences.
const _kProgressKey = 'curriculum_progress';

/// Stores which lesson IDs the user has completed.
/// Persistent via SharedPreferences (device-local only).
class CurriculumProgressNotifier extends StateNotifier<Set<String>> {
  CurriculumProgressNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_kProgressKey);
    if (json != null) {
      final List<dynamic> ids = jsonDecode(json);
      state = ids.cast<String>().toSet();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProgressKey, jsonEncode(state.toList()));
  }

  /// Mark a lesson as completed.
  void completeLesson(String lessonId) {
    state = {...state, lessonId};
    _persist();
  }

  /// Un-mark a lesson.
  void uncompleteLesson(String lessonId) {
    state = {...state}..remove(lessonId);
    _persist();
  }

  /// Number of completed lessons in a given module.
  int completedInModule(CurriculumModule module) =>
      module.lessons.where((l) => state.contains(l.id)).length;

  /// Progress fraction [0..1] for a given module.
  double moduleProgress(CurriculumModule module) {
    if (module.lessons.isEmpty) return 0;
    return completedInModule(module) / module.lessons.length;
  }
}

/// Provider for curriculum progress (set of completed lesson IDs).
final curriculumProgressProvider =
    StateNotifierProvider<CurriculumProgressNotifier, Set<String>>((ref) {
      return CurriculumProgressNotifier();
    });

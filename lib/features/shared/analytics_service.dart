import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized service for tracking user interactions through Firebase Analytics.
class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logLessonStart(String moduleId, String lessonId) async {
    try {
      await _analytics.logEvent(
        name: 'lesson_start',
        parameters: {'module_id': moduleId, 'lesson_id': lessonId},
      );
    } catch (e) {
      debugPrint('Analytics error (logLessonStart): $e');
    }
  }

  static Future<void> logStepExecuted(String moduleId, String lessonId) async {
    try {
      await _analytics.logEvent(
        name: 'step_executed',
        parameters: {'module_id': moduleId, 'lesson_id': lessonId},
      );
    } catch (e) {
      debugPrint('Analytics error (logStepExecuted): $e');
    }
  }

  static Future<void> logModuleCompleted(String moduleId) async {
    try {
      await _analytics.logEvent(
        name: 'module_completed',
        parameters: {'module_id': moduleId},
      );
    } catch (e) {
      debugPrint('Analytics error (logModuleCompleted): $e');
    }
  }
}

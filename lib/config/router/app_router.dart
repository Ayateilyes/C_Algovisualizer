import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/editor/presentation/screens/editor_screen.dart';
import '../../features/curriculum/presentation/screens/curriculum_screen.dart';
import '../../features/curriculum/presentation/screens/module_screen.dart';
import '../../features/curriculum/presentation/screens/lesson_screen.dart';
import '../../features/visualizer/presentation/screens/sorting_visualizer_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';

// ─── Route path constants ────────────────────────────────────────────────────
class AppRoutes {
  AppRoutes._();

  static const String welcome = '/';
  static const String editor = '/editor';
  static const String curriculum = '/curriculum';
  static const String course = '/course/:id';
  static const String lesson = '/lesson/:moduleId/:lessonId';
  static const String sortingVisualizer = '/sorting_visualizer';
}

// ─── Router factory ───────────────────────────────────────────────────────────
GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.editor,
        name: 'editor',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const EditorScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.curriculum,
        name: 'curriculum',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CurriculumScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.course,
        name: 'course',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ModuleScreen(moduleId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.lesson,
        name: 'lesson',
        builder: (context, state) {
          final moduleId = state.pathParameters['moduleId'] ?? '';
          final lessonId = state.pathParameters['lessonId'] ?? '';
          return LessonScreen(moduleId: moduleId, lessonId: lessonId);
        },
      ),
      GoRoute(
        path: AppRoutes.sortingVisualizer,
        name: 'sortingVisualizer',
        builder: (context, state) => const SortingVisualizerScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
}

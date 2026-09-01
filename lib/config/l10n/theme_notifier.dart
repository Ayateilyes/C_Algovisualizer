import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages dark/light theme toggle.
/// Dark mode is default (true).
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(true); // dark mode default

  void toggle() => state = !state;
  void setDark() => state = true;
  void setLight() => state = false;
}

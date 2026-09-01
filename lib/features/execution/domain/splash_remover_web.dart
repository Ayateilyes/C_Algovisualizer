// ignore: uri_does_not_exist, avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

/// Web implementation: calls window._removeSplash() defined in index.html.
/// This triggers the CSS fade-out animation on the splash overlay.
void removeSplash() {
  try {
    final fn = js_util.getProperty<Object?>(
      js_util.globalThis,
      '_removeSplash',
    );
    if (fn != null) {
      js_util.callMethod<void>(js_util.globalThis, '_removeSplash', []);
    }
  } catch (_) {
    // Silently ignore — splash will be removed by the JS fallback timer.
  }
}

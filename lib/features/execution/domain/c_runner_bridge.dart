// Conditional import: dart:js_util is only available on web.
// On other platforms the stub returns a "not supported" error.
export 'c_runner_bridge_stub.dart'
    if (dart.library.js_util) 'c_runner_bridge_web.dart';

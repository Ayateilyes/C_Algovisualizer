// This file is only imported on web (conditional import in c_runner_bridge.dart).
// On non-web the analyzer reports uri_does_not_exist — this is expected.
// ignore: uri_does_not_exist, avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;
import '../domain/scanf_input.dart';
import 'execution_result.dart';
import 'execution_step.dart';

/// Calls `window.CRunner.detectInputs(src)` and converts the result to Dart.
List<ScanfInput> detectInputsFromC(String src) {
  try {
    final cRunner = js_util.getProperty<Object>(js_util.globalThis, 'CRunner');
    final jsResult = js_util.callMethod<Object>(cRunner, 'detectInputs', [src]);
    final len = (js_util.getProperty<Object>(jsResult, 'length') as num)
        .toInt();
    final results = <ScanfInput>[];
    for (int i = 0; i < len; i++) {
      final item = js_util.getProperty<Object>(jsResult, i);
      results.add(
        ScanfInput(
          format: js_util.getProperty<String>(item, 'format'),
          varName: js_util.getProperty<String>(item, 'varName'),
        ),
      );
    }
    return results;
  } catch (_) {
    return const [];
  }
}

/// Web implementation: calls `window.CRunner.run(code, inputs)` via dart:js_util.
Future<ExecutionResult> runCCode(
  String code, {
  List<String> inputs = const [],
}) async {
  try {
    final cRunner = js_util.getProperty<Object>(js_util.globalThis, 'CRunner');
    final jsResult = js_util.callMethod<Object>(cRunner, 'run', [
      code,
      js_util.jsify(inputs),
    ]);

    // Parse structured error info if present
    int? errorLine;
    int? errorColumn;
    String? errorMessage;
    String? errorHint;
    String? errorSourceLine;

    try {
      final errInfo = js_util.getProperty<Object?>(jsResult, 'errorInfo');
      if (errInfo != null) {
        final line = js_util.getProperty<Object?>(errInfo, 'line');
        if (line != null) {
          errorLine = (line as num).toInt();
          if (errorLine <= 0) errorLine = null;
        }
        final col = js_util.getProperty<Object?>(errInfo, 'column');
        if (col != null) {
          errorColumn = (col as num).toInt();
          if (errorColumn <= 0) errorColumn = null;
        }
        errorMessage = js_util.getProperty<String?>(errInfo, 'message');
        errorHint = js_util.getProperty<String?>(errInfo, 'hint');
        errorSourceLine = js_util.getProperty<String?>(errInfo, 'sourceLine');
      }
    } catch (_) {
      // errorInfo not present — fine, leave null
    }

    return ExecutionResult(
      stdout: js_util.getProperty<String>(jsResult, 'stdout'),
      stderr: js_util.getProperty<String>(jsResult, 'stderr'),
      exitCode: (js_util.getProperty<Object>(jsResult, 'exitCode') as num)
          .toInt(),
      elapsed: Duration(
        milliseconds: (js_util.getProperty<Object>(jsResult, 'elapsed') as num)
            .toInt(),
      ),
      success: js_util.getProperty<bool>(jsResult, 'success'),
      errorLine: errorLine,
      errorColumn: errorColumn,
      errorMessage: errorMessage,
      errorHint: errorHint,
      errorSourceLine: errorSourceLine,
    );
  } catch (e) {
    return ExecutionResult(
      stdout: '',
      stderr:
          'Bridge error: $e\nMake sure c_runner.js is loaded in web/index.html.',
      exitCode: 1,
      elapsed: Duration.zero,
      success: false,
    );
  }
}

/// Web implementation: calls `window.CRunner.trace(code, inputs)` and converts result
/// to a list of [ExecutionStep]s.
Future<({ExecutionResult result, List<ExecutionStep> steps})> traceC(
  String code, {
  List<String> inputs = const [],
}) async {
  try {
    final cRunner = js_util.getProperty<Object>(js_util.globalThis, 'CRunner');
    final jsResult = js_util.callMethod<Object>(cRunner, 'trace', [
      code,
      js_util.jsify(inputs),
    ]);

    final stepsJs = js_util.getProperty<Object>(jsResult, 'steps');
    final stepsLen = (js_util.getProperty<Object>(stepsJs, 'length') as num)
        .toInt();

    final steps = <ExecutionStep>[];
    for (int i = 0; i < stepsLen; i++) {
      final stepObj = js_util.getProperty<Object>(stepsJs, i);
      final line = (js_util.getProperty<Object>(stepObj, 'line') as num)
          .toInt();
      final varsJs = js_util.getProperty<Object>(stepObj, 'vars');
      final output = js_util.getProperty<String>(stepObj, 'output');

      // Convert JS vars object to Dart Map
      final keys = js_util.callMethod<Object>(
        js_util.getProperty<Object>(js_util.globalThis, 'Object'),
        'keys',
        [varsJs],
      );
      final keysLen = (js_util.getProperty<Object>(keys, 'length') as num)
          .toInt();
      final variables = <String, String>{};
      for (int k = 0; k < keysLen; k++) {
        final key = js_util.getProperty<String>(keys, k);
        variables[key] = js_util.getProperty<String>(varsJs, key);
      }

      steps.add(
        ExecutionStep(
          line: line,
          variables: variables,
          outputSoFar: output,
          callStack: _parseCallStack(stepObj),
          heap: _parseHeap(stepObj),
        ),
      );
    }

    // Parse structured error info if present
    int? errorLine;
    int? errorColumn;
    String? errorMessage;
    String? errorHint;
    String? errorSourceLine;

    try {
      final errInfo = js_util.getProperty<Object?>(jsResult, 'errorInfo');
      if (errInfo != null) {
        final line = js_util.getProperty<Object?>(errInfo, 'line');
        if (line != null) {
          errorLine = (line as num).toInt();
          if (errorLine <= 0) errorLine = null;
        }
        final col = js_util.getProperty<Object?>(errInfo, 'column');
        if (col != null) {
          errorColumn = (col as num).toInt();
          if (errorColumn <= 0) errorColumn = null;
        }
        errorMessage = js_util.getProperty<String?>(errInfo, 'message');
        errorHint = js_util.getProperty<String?>(errInfo, 'hint');
        errorSourceLine = js_util.getProperty<String?>(errInfo, 'sourceLine');
      }
    } catch (_) {
      // errorInfo not present
    }

    final result = ExecutionResult(
      stdout: js_util.getProperty<String>(jsResult, 'stdout'),
      stderr: js_util.getProperty<String>(jsResult, 'stderr'),
      exitCode: (js_util.getProperty<Object>(jsResult, 'exitCode') as num)
          .toInt(),
      elapsed: Duration(
        milliseconds: (js_util.getProperty<Object>(jsResult, 'elapsed') as num)
            .toInt(),
      ),
      success: js_util.getProperty<bool>(jsResult, 'success'),
      errorLine: errorLine,
      errorColumn: errorColumn,
      errorMessage: errorMessage,
      errorHint: errorHint,
      errorSourceLine: errorSourceLine,
    );

    return (result: result, steps: steps);
  } catch (e) {
    return (
      result: ExecutionResult(
        stdout: '',
        stderr: 'Trace bridge error: $e',
        exitCode: 1,
        elapsed: Duration.zero,
        success: false,
      ),
      steps: const <ExecutionStep>[],
    );
  }
}

/// Parse the JS callStack array from a step object.
List<StackFrame> _parseCallStack(Object stepObj) {
  try {
    final csJs = js_util.getProperty<Object?>(stepObj, 'callStack');
    if (csJs == null) return const [StackFrame(functionName: 'main', line: 0)];

    final csLen = (js_util.getProperty<Object>(csJs, 'length') as num).toInt();
    final frames = <StackFrame>[];
    for (int f = 0; f < csLen; f++) {
      final fObj = js_util.getProperty<Object>(csJs, f);
      final fn = js_util.getProperty<String>(fObj, 'fn');
      final line = (js_util.getProperty<Object>(fObj, 'line') as num).toInt();
      frames.add(StackFrame(functionName: fn, line: line));
    }
    return frames;
  } catch (_) {
    return const [StackFrame(functionName: 'main', line: 0)];
  }
}

/// Parse the JS heap array from a step object into [HeapBlock] list.
List<HeapBlock> _parseHeap(Object stepObj) {
  try {
    final heapJs = js_util.getProperty<Object?>(stepObj, 'heap');
    if (heapJs == null) return const [];
    final len = (js_util.getProperty<Object>(heapJs, 'length') as num).toInt();
    final blocks = <HeapBlock>[];
    for (int i = 0; i < len; i++) {
      final bObj = js_util.getProperty<Object>(heapJs, i);
      final addr = (js_util.getProperty<Object>(bObj, 'addr') as num).toInt();
      final size = (js_util.getProperty<Object>(bObj, 'size') as num).toInt();
      final label = js_util.getProperty<String>(bObj, 'label');
      final isFree = js_util.getProperty<bool>(bObj, 'free');
      // Parse cells array
      final cellsJs = js_util.getProperty<Object?>(bObj, 'cells');
      final values = <String>[];
      if (cellsJs != null) {
        final cLen = (js_util.getProperty<Object>(cellsJs, 'length') as num)
            .toInt();
        for (int c = 0; c < cLen; c++) {
          final cell = js_util.getProperty<Object?>(cellsJs, c);
          values.add(cell?.toString() ?? '0');
        }
      }
      blocks.add(
        HeapBlock(
          address: addr,
          size: size,
          label: label,
          isFree: isFree,
          values: values,
        ),
      );
    }
    return blocks;
  } catch (_) {
    return const [];
  }
}

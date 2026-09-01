import '../domain/scanf_input.dart';
import 'execution_result.dart';
import 'execution_step.dart';

/// Stub implementation for non-web platforms.

List<ScanfInput> detectInputsFromC(String src) => const [];

Future<ExecutionResult> runCCode(
  String code, {
  List<String> inputs = const [],
}) async {
  return const ExecutionResult(
    stdout: '',
    stderr: 'C execution is only supported on the web platform.',
    exitCode: 1,
    elapsed: Duration.zero,
    success: false,
  );
}

Future<({ExecutionResult result, List<ExecutionStep> steps})> traceC(
  String code, {
  List<String> inputs = const [],
}) async {
  return (
    result: const ExecutionResult(
      stdout: '',
      stderr: 'Trace is only supported on the web platform.',
      exitCode: 1,
      elapsed: Duration.zero,
      success: false,
    ),
    steps: const <ExecutionStep>[],
  );
}

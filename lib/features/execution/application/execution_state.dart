import '../domain/execution_result.dart';
import '../domain/scanf_input.dart';

/// All possible states of the Run pipeline.
enum RunStatus {
  /// Editor is idle — nothing running.
  idle,

  /// Transpiling + executing — spinner shown.
  running,

  /// Awaiting user input for one or more scanf() calls.
  scanfPending,

  /// Execution finished successfully (exit code 0).
  done,

  /// Execution finished with an error (compile/runtime, or exit code ≠ 0).
  error,
}

/// Snapshot of the execution pipeline at any point in time.
class ExecutionState {
  const ExecutionState({
    this.status = RunStatus.idle,
    this.result = ExecutionResult.empty,
    this.pendingInputs = const [],
    this.collectedInputs = const [],
    this.scanfCode, // code to run after inputs collected
  });

  final RunStatus status;

  /// Last result (stdout / stderr / exitCode / elapsed).
  final ExecutionResult result;

  /// Detected scanf() calls that still need user input.
  final List<ScanfInput> pendingInputs;

  /// Already-collected input strings (in order of scanf calls).
  final List<String> collectedInputs;

  /// Source code saved while gathering scanf inputs.
  final String? scanfCode;

  bool get isRunning => status == RunStatus.running;
  bool get hasOutput => result.stdout.isNotEmpty || result.stderr.isNotEmpty;
  bool get isScanfPending => status == RunStatus.scanfPending;

  ExecutionState copyWith({
    RunStatus? status,
    ExecutionResult? result,
    List<ScanfInput>? pendingInputs,
    List<String>? collectedInputs,
    String? scanfCode,
  }) {
    return ExecutionState(
      status: status ?? this.status,
      result: result ?? this.result,
      pendingInputs: pendingInputs ?? this.pendingInputs,
      collectedInputs: collectedInputs ?? this.collectedInputs,
      scanfCode: scanfCode ?? this.scanfCode,
    );
  }
}

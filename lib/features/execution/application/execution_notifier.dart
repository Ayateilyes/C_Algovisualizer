import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../editor/domain/editor_state.dart';
import '../domain/c_runner_bridge.dart';
import 'execution_state.dart';

/// Riverpod provider for execution state.
final executionNotifierProvider =
    StateNotifierProvider<ExecutionNotifier, ExecutionState>(
      (ref) => ExecutionNotifier(ref),
    );

/// Manages the full lifecycle of a C program run:
///   idle → [scanfPending *] → running → done | error
///
/// When the source has scanf calls, we pause in `scanfPending` and
/// collect one input per scanf (via [submitScanfInput]) before executing.
class ExecutionNotifier extends StateNotifier<ExecutionState> {
  ExecutionNotifier(this._ref) : super(const ExecutionState());

  final Ref _ref;

  /// Kicks off execution of [code].
  /// If the code has scanf calls, transitions to [RunStatus.scanfPending]
  /// and waits for input via [submitScanfInput]. Otherwise runs directly.
  Future<void> run(String code) async {
    if (state.isRunning || state.isScanfPending) return;

    // Clear previous error highlight
    _ref.read(errorLineProvider.notifier).state = null;

    // Detect scanf calls
    final inputs = detectInputsFromC(code);

    if (inputs.isNotEmpty) {
      // Pause and ask for inputs
      state = ExecutionState(
        status: RunStatus.scanfPending,
        pendingInputs: inputs,
        collectedInputs: const [],
        scanfCode: code,
      );
      return;
    }

    // No scanf — run immediately
    await _executeWithInputs(code, const []);
  }

  /// Called by the UI when the user submits one input value for scanf.
  /// Advances through the pending inputs queue. When all are collected,
  /// runs the program.
  Future<void> submitScanfInput(String value) async {
    if (!state.isScanfPending) return;

    final collected = [...state.collectedInputs, value];
    final remaining = state.pendingInputs.skip(collected.length).toList();

    if (remaining.isEmpty) {
      // All inputs collected — now run
      final code = state.scanfCode!;
      await _executeWithInputs(code, collected);
    } else {
      // Still more inputs needed
      state = state.copyWith(collectedInputs: collected);
    }
  }

  /// Internal: actually run the code with pre-collected inputs.
  Future<void> _executeWithInputs(String code, List<String> inputs) async {
    state = state.copyWith(
      status: RunStatus.running,
      pendingInputs: const [],
      collectedInputs: const [],
    );

    final result = await runCCode(code, inputs: inputs);

    state = ExecutionState(
      status: result.success ? RunStatus.done : RunStatus.error,
      result: result,
    );

    // Set error line for editor highlight
    if (!result.success && result.hasErrorInfo) {
      _ref.read(errorLineProvider.notifier).state = result.errorLine;
    }
  }

  /// Resets to idle and clears output + error highlight.
  void clear() {
    _ref.read(errorLineProvider.notifier).state = null;
    state = const ExecutionState();
  }
}

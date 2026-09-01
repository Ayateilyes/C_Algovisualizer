import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/c_runner_bridge.dart';
import '../domain/execution_step.dart';
import '../domain/execution_result.dart';
import '../domain/scanf_input.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum StepStatus {
  /// No trace loaded.
  idle,

  /// Generating trace (awaiting JS call).
  tracing,

  /// Awaiting scanf input before tracing can begin.
  scanfPending,

  /// Trace ready, paused at [currentIndex].
  paused,

  /// Auto-playing through steps.
  playing,

  /// Trace failed.
  error,
}

class StepState {
  const StepState({
    this.status = StepStatus.idle,
    this.steps = const [],
    this.currentIndex = 0,
    this.errorMessage = '',
    this.result = ExecutionResult.empty,
    this.pendingInputs = const [],
    this.collectedInputs = const [],
    this.scanfCode,
  });

  final StepStatus status;
  final List<ExecutionStep> steps;
  final int currentIndex;
  final String errorMessage;

  /// Final ExecutionResult from the trace run (stdout/stderr/exitCode).
  final ExecutionResult result;

  /// Detected scanf() calls still awaiting user input (trace mode).
  final List<ScanfInput> pendingInputs;

  /// Already-collected inputs for trace mode scanf.
  final List<String> collectedInputs;

  /// Source code saved while collecting scanf inputs.
  final String? scanfCode;

  bool get isIdle => status == StepStatus.idle;
  bool get isTracing => status == StepStatus.tracing;
  bool get isPaused => status == StepStatus.paused;
  bool get isPlaying => status == StepStatus.playing;
  bool get isScanfPending => status == StepStatus.scanfPending;
  bool get hasSteps => steps.isNotEmpty;

  int get totalSteps => steps.length;

  bool get canStepBack => currentIndex > 0;
  bool get canStepForward => currentIndex < totalSteps - 1;

  ExecutionStep? get currentStep =>
      hasSteps && currentIndex < totalSteps ? steps[currentIndex] : null;

  int get currentLine => currentStep?.line ?? -1;

  StepState copyWith({
    StepStatus? status,
    List<ExecutionStep>? steps,
    int? currentIndex,
    String? errorMessage,
    ExecutionResult? result,
    List<ScanfInput>? pendingInputs,
    List<String>? collectedInputs,
    String? scanfCode,
  }) {
    return StepState(
      status: status ?? this.status,
      steps: steps ?? this.steps,
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: errorMessage ?? this.errorMessage,
      result: result ?? this.result,
      pendingInputs: pendingInputs ?? this.pendingInputs,
      collectedInputs: collectedInputs ?? this.collectedInputs,
      scanfCode: scanfCode ?? this.scanfCode,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

final stepNotifierProvider = StateNotifierProvider<StepNotifier, StepState>(
  (ref) => StepNotifier(),
);

class StepNotifier extends StateNotifier<StepState> {
  StepNotifier() : super(const StepState());

  Timer? _playTimer;

  /// Generate execution trace for [code] and move to step 0.
  /// If the code has scanf calls, transitions to [StepStatus.scanfPending]
  /// and waits for [submitScanfInput] to be called for each one.
  Future<void> startTrace(String code) async {
    _cancelPlay();

    // Detect scanf calls before tracing
    final inputs = detectInputsFromC(code);
    if (inputs.isNotEmpty) {
      state = StepState(
        status: StepStatus.scanfPending,
        pendingInputs: inputs,
        collectedInputs: const [],
        scanfCode: code,
      );
      return;
    }

    await _doTrace(code, const []);
  }

  /// Called by the UI when the user submits one input value for sizeof in trace
  /// mode. Advances through the pending inputs queue. When all are collected,
  /// starts the trace.
  Future<void> submitScanfInput(String value) async {
    if (!state.isScanfPending) return;

    final collected = [...state.collectedInputs, value];
    final remaining = state.pendingInputs.skip(collected.length).toList();

    if (remaining.isEmpty) {
      final code = state.scanfCode!;
      await _doTrace(code, collected);
    } else {
      state = state.copyWith(collectedInputs: collected);
    }
  }

  /// Internal: run the actual trace with pre-collected inputs.
  Future<void> _doTrace(String code, List<String> inputs) async {
    state = state.copyWith(
      status: StepStatus.tracing,
      steps: [],
      currentIndex: 0,
      pendingInputs: const [],
      collectedInputs: const [],
    );

    final (:result, :steps) = await traceC(code, inputs: inputs);

    if (!result.success || steps.isEmpty) {
      state = state.copyWith(
        status: StepStatus.error,
        errorMessage: result.stderr.isNotEmpty
            ? result.stderr
            : 'No execution steps generated.',
        result: result,
      );
      return;
    }

    state = StepState(
      status: StepStatus.paused,
      steps: steps,
      currentIndex: 0,
      result: result,
    );
  }

  /// Advance one step forward.
  void stepForward() {
    if (!state.canStepForward) return;
    _cancelPlay();
    state = state.copyWith(
      status: StepStatus.paused,
      currentIndex: state.currentIndex + 1,
    );
  }

  /// Go one step back.
  void stepBackward() {
    if (!state.canStepBack) return;
    _cancelPlay();
    state = state.copyWith(
      status: StepStatus.paused,
      currentIndex: state.currentIndex - 1,
    );
  }

  /// Jump to first step.
  void jumpToStart() {
    _cancelPlay();
    state = state.copyWith(status: StepStatus.paused, currentIndex: 0);
  }

  /// Jump to last step.
  void jumpToEnd() {
    _cancelPlay();
    state = state.copyWith(
      status: StepStatus.paused,
      currentIndex: state.totalSteps - 1,
    );
  }

  /// Auto-play with [intervalMs] between steps.
  void play({int intervalMs = 600}) {
    if (!state.hasSteps || !state.canStepForward) return;
    state = state.copyWith(status: StepStatus.playing);
    _schedulePlay(intervalMs);
  }

  void _schedulePlay(int intervalMs) {
    _playTimer = Timer(Duration(milliseconds: intervalMs), () {
      if (!state.canStepForward) {
        state = state.copyWith(status: StepStatus.paused);
        return;
      }
      state = state.copyWith(currentIndex: state.currentIndex + 1);
      if (state.canStepForward && state.isPlaying) {
        _schedulePlay(intervalMs);
      } else {
        state = state.copyWith(status: StepStatus.paused);
      }
    });
  }

  /// Pause auto-play.
  void pause() {
    _cancelPlay();
    state = state.copyWith(status: StepStatus.paused);
  }

  /// Reset to idle, clearing the trace.
  void reset() {
    _cancelPlay();
    state = const StepState();
  }

  void _cancelPlay() {
    _playTimer?.cancel();
    _playTimer = null;
  }

  @override
  void dispose() {
    _cancelPlay();
    super.dispose();
  }
}

/// A single frame on the call stack during traced execution.
class StackFrame {
  const StackFrame({required this.functionName, required this.line});

  /// Name of the function (e.g. "main", "factorial").
  final String functionName;

  /// Current source line inside this function (1-indexed, -1 for end).
  final int line;

  @override
  String toString() => '$functionName:$line';
}

/// A single heap allocation block (malloc / calloc result).
class HeapBlock {
  const HeapBlock({
    required this.address,
    required this.size,
    required this.label,
    required this.isFree,
    this.values = const [],
  });

  /// Simulated memory address (e.g. 0x1000, 0x1010 …).
  final int address;

  /// Number of allocated bytes / cells.
  final int size;

  /// Variable name or expression that holds the pointer (for display).
  final String label;

  /// True when free() has been called on this block.
  final bool isFree;

  /// Cell values (if written via pointer arithmetic / array writes).
  final List<String> values;

  HeapBlock copyWith({
    int? address,
    int? size,
    String? label,
    bool? isFree,
    List<String>? values,
  }) => HeapBlock(
    address: address ?? this.address,
    size: size ?? this.size,
    label: label ?? this.label,
    isFree: isFree ?? this.isFree,
    values: values ?? this.values,
  );
}

/// A single step in a traced C program execution.
class ExecutionStep {
  const ExecutionStep({
    required this.line,
    required this.variables,
    required this.outputSoFar,
    this.callStack = const [],
    this.heap = const [],
  });

  /// 1-indexed C source line that was just executed.
  /// -1 represents the synthetic "end of program" step.
  final int line;

  /// Snapshot of all variables visible at this point.
  final Map<String, String> variables;

  /// Accumulated stdout output up to and including this step.
  final String outputSoFar;

  /// Current call stack snapshot: bottom → top.
  /// Always contains at least one frame (main).
  final List<StackFrame> callStack;

  /// Heap allocations snapshot at this step.
  /// Each entry is a [HeapBlock] created by malloc/calloc.
  final List<HeapBlock> heap;

  bool get isEndStep => line == -1;
}

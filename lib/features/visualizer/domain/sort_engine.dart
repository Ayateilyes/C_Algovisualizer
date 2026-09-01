import 'dart:math';

/// Represents a single step in a sorting animation.
class SortStep {
  const SortStep({
    required this.array,
    required this.comparing,
    required this.swapping,
    required this.sorted,
    this.pivot = -1,
    this.label = '',
  });

  /// Current state of the array.
  final List<int> array;

  /// Indices being compared (highlighted).
  final List<int> comparing;

  /// Indices being swapped (animated).
  final List<int> swapping;

  /// Indices that are in their final sorted position.
  final List<int> sorted;

  /// Pivot index (for quicksort).
  final int pivot;

  /// Human-readable description of this step.
  final String label;
}

/// Supported sorting algorithms.
enum SortAlgorithm {
  bubble,
  selection,
  insertion,
  merge,
  quick;

  String get displayName => switch (this) {
    SortAlgorithm.bubble => 'Bubble Sort',
    SortAlgorithm.selection => 'Selection Sort',
    SortAlgorithm.insertion => 'Insertion Sort',
    SortAlgorithm.merge => 'Merge Sort',
    SortAlgorithm.quick => 'Quick Sort',
  };

  String get complexity => switch (this) {
    SortAlgorithm.bubble => 'O(n²)',
    SortAlgorithm.selection => 'O(n²)',
    SortAlgorithm.insertion => 'O(n²)',
    SortAlgorithm.merge => 'O(n log n)',
    SortAlgorithm.quick => 'O(n log n)',
  };

  String get description => switch (this) {
    SortAlgorithm.bubble => 'Repeatedly swap adjacent elements if out of order',
    SortAlgorithm.selection => 'Find the minimum and place it at the front',
    SortAlgorithm.insertion => 'Insert each element into its correct position',
    SortAlgorithm.merge => 'Divide, sort recursively, and merge halves',
    SortAlgorithm.quick => 'Pick pivot, partition, sort partitions recursively',
  };
}

/// Generates all steps for a given sorting algorithm.
class SortEngine {
  SortEngine._();

  static List<int> generateArray(int size, {int maxVal = 100}) {
    final rng = Random();
    return List.generate(size, (_) => rng.nextInt(maxVal) + 5);
  }

  static List<SortStep> generate(SortAlgorithm algo, List<int> input) {
    final arr = List<int>.from(input);
    return switch (algo) {
      SortAlgorithm.bubble => _bubbleSort(arr),
      SortAlgorithm.selection => _selectionSort(arr),
      SortAlgorithm.insertion => _insertionSort(arr),
      SortAlgorithm.merge => _mergeSort(arr),
      SortAlgorithm.quick => _quickSort(arr),
    };
  }

  // ── Bubble Sort ──────────────────────────────────────────────────────────
  static List<SortStep> _bubbleSort(List<int> arr) {
    final steps = <SortStep>[];
    final n = arr.length;
    final sorted = <int>[];

    steps.add(
      SortStep(
        array: List.from(arr),
        comparing: [],
        swapping: [],
        sorted: [],
        label: 'Initial array',
      ),
    );

    for (int i = 0; i < n - 1; i++) {
      for (int j = 0; j < n - i - 1; j++) {
        // Compare
        steps.add(
          SortStep(
            array: List.from(arr),
            comparing: [j, j + 1],
            swapping: [],
            sorted: List.from(sorted),
            label: 'Compare ${arr[j]} and ${arr[j + 1]}',
          ),
        );

        if (arr[j] > arr[j + 1]) {
          // Swap
          final temp = arr[j];
          arr[j] = arr[j + 1];
          arr[j + 1] = temp;

          steps.add(
            SortStep(
              array: List.from(arr),
              comparing: [],
              swapping: [j, j + 1],
              sorted: List.from(sorted),
              label: 'Swap ${arr[j + 1]} ↔ ${arr[j]}',
            ),
          );
        }
      }
      sorted.add(n - 1 - i);
    }
    sorted.add(0);

    steps.add(
      SortStep(
        array: List.from(arr),
        comparing: [],
        swapping: [],
        sorted: List.generate(n, (i) => i),
        label: 'Sorted!',
      ),
    );

    return steps;
  }

  // ── Selection Sort ───────────────────────────────────────────────────────
  static List<SortStep> _selectionSort(List<int> arr) {
    final steps = <SortStep>[];
    final n = arr.length;
    final sorted = <int>[];

    steps.add(
      SortStep(
        array: List.from(arr),
        comparing: [],
        swapping: [],
        sorted: [],
        label: 'Initial array',
      ),
    );

    for (int i = 0; i < n - 1; i++) {
      int minIdx = i;
      for (int j = i + 1; j < n; j++) {
        steps.add(
          SortStep(
            array: List.from(arr),
            comparing: [minIdx, j],
            swapping: [],
            sorted: List.from(sorted),
            label: 'Find min: comparing ${arr[minIdx]} and ${arr[j]}',
          ),
        );

        if (arr[j] < arr[minIdx]) {
          minIdx = j;
        }
      }

      if (minIdx != i) {
        final temp = arr[i];
        arr[i] = arr[minIdx];
        arr[minIdx] = temp;

        steps.add(
          SortStep(
            array: List.from(arr),
            comparing: [],
            swapping: [i, minIdx],
            sorted: List.from(sorted),
            label: 'Place minimum ${arr[i]} at position $i',
          ),
        );
      }
      sorted.add(i);
    }
    sorted.add(n - 1);

    steps.add(
      SortStep(
        array: List.from(arr),
        comparing: [],
        swapping: [],
        sorted: List.generate(n, (i) => i),
        label: 'Sorted!',
      ),
    );

    return steps;
  }

  // ── Insertion Sort ───────────────────────────────────────────────────────
  static List<SortStep> _insertionSort(List<int> arr) {
    final steps = <SortStep>[];
    final n = arr.length;

    steps.add(
      SortStep(
        array: List.from(arr),
        comparing: [],
        swapping: [],
        sorted: [0],
        label: 'Initial array',
      ),
    );

    for (int i = 1; i < n; i++) {
      final key = arr[i];
      int j = i - 1;

      steps.add(
        SortStep(
          array: List.from(arr),
          comparing: [i],
          swapping: [],
          sorted: List.generate(i, (k) => k),
          label: 'Insert $key into sorted portion',
        ),
      );

      while (j >= 0 && arr[j] > key) {
        arr[j + 1] = arr[j];
        steps.add(
          SortStep(
            array: List.from(arr),
            comparing: [j, j + 1],
            swapping: [j, j + 1],
            sorted: List.generate(i, (k) => k),
            label: 'Shift ${arr[j + 1]} right',
          ),
        );
        j--;
      }
      arr[j + 1] = key;

      steps.add(
        SortStep(
          array: List.from(arr),
          comparing: [],
          swapping: [],
          sorted: List.generate(i + 1, (k) => k),
          label: 'Placed $key at position ${j + 1}',
        ),
      );
    }

    steps.add(
      SortStep(
        array: List.from(arr),
        comparing: [],
        swapping: [],
        sorted: List.generate(n, (i) => i),
        label: 'Sorted!',
      ),
    );

    return steps;
  }

  // ── Merge Sort ───────────────────────────────────────────────────────────
  static List<SortStep> _mergeSort(List<int> arr) {
    final steps = <SortStep>[];
    final n = arr.length;
    final sorted = <int>{};

    steps.add(
      SortStep(
        array: List.from(arr),
        comparing: [],
        swapping: [],
        sorted: [],
        label: 'Initial array',
      ),
    );

    void merge(int l, int m, int r) {
      final left = arr.sublist(l, m + 1);
      final right = arr.sublist(m + 1, r + 1);
      int i = 0, j = 0, k = l;

      while (i < left.length && j < right.length) {
        steps.add(
          SortStep(
            array: List.from(arr),
            comparing: [l + i, m + 1 + j],
            swapping: [],
            sorted: sorted.toList(),
            label: 'Merge: compare ${left[i]} and ${right[j]}',
          ),
        );

        if (left[i] <= right[j]) {
          arr[k] = left[i];
          i++;
        } else {
          arr[k] = right[j];
          j++;
        }
        k++;
      }

      while (i < left.length) {
        arr[k] = left[i];
        i++;
        k++;
      }
      while (j < right.length) {
        arr[k] = right[j];
        j++;
        k++;
      }

      steps.add(
        SortStep(
          array: List.from(arr),
          comparing: [],
          swapping: List.generate(r - l + 1, (i) => l + i),
          sorted: sorted.toList(),
          label: 'Merged [$l..$r]',
        ),
      );
    }

    void sort(int l, int r) {
      if (l < r) {
        final m = (l + r) ~/ 2;
        sort(l, m);
        sort(m + 1, r);
        merge(l, m, r);
      } else if (l == r) {
        sorted.add(l);
      }
    }

    sort(0, n - 1);

    steps.add(
      SortStep(
        array: List.from(arr),
        comparing: [],
        swapping: [],
        sorted: List.generate(n, (i) => i),
        label: 'Sorted!',
      ),
    );

    return steps;
  }

  // ── Quick Sort ───────────────────────────────────────────────────────────
  static List<SortStep> _quickSort(List<int> arr) {
    final steps = <SortStep>[];
    final n = arr.length;
    final sorted = <int>{};

    steps.add(
      SortStep(
        array: List.from(arr),
        comparing: [],
        swapping: [],
        sorted: [],
        label: 'Initial array',
      ),
    );

    int partition(int low, int high) {
      final pivot = arr[high];
      int i = low - 1;

      steps.add(
        SortStep(
          array: List.from(arr),
          comparing: [],
          swapping: [],
          sorted: sorted.toList(),
          pivot: high,
          label: 'Pivot = $pivot',
        ),
      );

      for (int j = low; j < high; j++) {
        steps.add(
          SortStep(
            array: List.from(arr),
            comparing: [j, high],
            swapping: [],
            sorted: sorted.toList(),
            pivot: high,
            label: 'Compare ${arr[j]} with pivot $pivot',
          ),
        );

        if (arr[j] < pivot) {
          i++;
          if (i != j) {
            final temp = arr[i];
            arr[i] = arr[j];
            arr[j] = temp;

            steps.add(
              SortStep(
                array: List.from(arr),
                comparing: [],
                swapping: [i, j],
                sorted: sorted.toList(),
                pivot: high,
                label: 'Swap ${arr[j]} ↔ ${arr[i]}',
              ),
            );
          }
        }
      }

      final temp = arr[i + 1];
      arr[i + 1] = arr[high];
      arr[high] = temp;

      sorted.add(i + 1);

      steps.add(
        SortStep(
          array: List.from(arr),
          comparing: [],
          swapping: [i + 1, high],
          sorted: sorted.toList(),
          pivot: i + 1,
          label: 'Place pivot $pivot at position ${i + 1}',
        ),
      );

      return i + 1;
    }

    void sort(int low, int high) {
      if (low < high) {
        final pi = partition(low, high);
        sort(low, pi - 1);
        sort(pi + 1, high);
      } else if (low == high) {
        sorted.add(low);
      }
    }

    sort(0, n - 1);

    steps.add(
      SortStep(
        array: List.from(arr),
        comparing: [],
        swapping: [],
        sorted: List.generate(n, (i) => i),
        label: 'Sorted!',
      ),
    );

    return steps;
  }
}

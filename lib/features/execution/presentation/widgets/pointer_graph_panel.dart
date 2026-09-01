import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../application/step_notifier.dart';
import '../../domain/execution_step.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

enum _NodeKind { variable, heap, nullNode }

class _Node {
  _Node({
    required this.id,
    required this.label,
    required this.value,
    required this.kind,
    this.address,
    this.isFree = false,
  });
  final String id;
  final String label;
  final String value;
  final _NodeKind kind;
  final String? address;
  final bool isFree;

  // Layout position (set during layout)
  Offset position = Offset.zero;
  final Size size = const Size(110, 44);

  Rect get rect => position & size;
  Offset get center => rect.center;
}

class _Edge {
  _Edge({required this.from, required this.to, required this.isNull});
  final String from;
  final String to;
  final bool isNull;
}

// ─── Graph builder from ExecutionStep ────────────────────────────────────────

class _GraphData {
  _GraphData({required this.nodes, required this.edges});
  final Map<String, _Node> nodes;
  final List<_Edge> edges;

  bool get isEmpty => nodes.isEmpty;
  bool get hasPointers => edges.isNotEmpty;
}

_GraphData _buildGraph(ExecutionStep? step) {
  if (step == null) return _GraphData(nodes: {}, edges: []);

  final nodes = <String, _Node>{};
  final edges = <_Edge>[];

  // Add stack variable nodes
  for (final entry in step.variables.entries) {
    nodes[entry.key] = _Node(
      id: entry.key,
      label: entry.key,
      value: entry.value,
      kind: _NodeKind.variable,
    );
  }

  // Add heap block nodes
  for (final block in step.heap) {
    final id = 'heap_${block.address}';
    final cellStr = block.values.isEmpty
        ? '[${List.filled(block.size, '0').join(', ')}]'
        : '[${block.values.join(', ')}]';
    nodes[id] = _Node(
      id: id,
      label: block.label,
      value: cellStr,
      kind: _NodeKind.heap,
      address: '0x${block.address.toRadixString(16).toUpperCase()}',
      isFree: block.isFree,
    );
  }

  // Build edges from pointer variables
  for (final entry in step.variables.entries) {
    final val = entry.value;

    if (val == 'null' || val == 'NULL' || val == '0') {
      // NULL pointer: add tombstone node + edge
      final nullId = 'null_${entry.key}';
      nodes[nullId] = _Node(
        id: nullId,
        label: 'NULL',
        value: '',
        kind: _NodeKind.nullNode,
      );
      edges.add(_Edge(from: entry.key, to: nullId, isNull: true));
    } else if (val.startsWith('&')) {
      // Points to variable: &x → find node 'x'
      final target = val.substring(1);
      if (nodes.containsKey(target)) {
        edges.add(_Edge(from: entry.key, to: target, isNull: false));
      }
    } else {
      // Check if it looks like a heap pointer (hex address)
      final hexRegex = RegExp(r'^0x[0-9A-Fa-f]+$');
      if (hexRegex.hasMatch(val)) {
        // Find heap block by address
        for (final block in step.heap) {
          final blockHex = '0x${block.address.toRadixString(16).toUpperCase()}';
          if (blockHex == val.toUpperCase()) {
            edges.add(
              _Edge(
                from: entry.key,
                to: 'heap_${block.address}',
                isNull: false,
              ),
            );
          }
        }
      }
      // Check for heap node id pattern (e.g. pointer variable value matches a label)
      for (final block in step.heap) {
        if (entry.value == block.label || entry.value == '&${block.label}') {
          edges.add(
            _Edge(from: entry.key, to: 'heap_${block.address}', isNull: false),
          );
        }
      }
    }
  }

  // Remove variable nodes that have no edges and no array/struct value
  // Keep only pointer nodes (those involved in edges) + heap nodes + null nodes
  final involvedIds = <String>{};
  for (final e in edges) {
    involvedIds.add(e.from);
    involvedIds.add(e.to);
  }
  // Also keep heap nodes always
  for (final block in step.heap) {
    involvedIds.add('heap_${block.address}');
  }

  // If no pointer relationships at all, show all variables
  if (edges.isEmpty && step.heap.isEmpty) {
    // Show all vars as boxes
  } else {
    // Remove non-involved plain variables
    nodes.removeWhere(
      (id, node) =>
          node.kind == _NodeKind.variable && !involvedIds.contains(id),
    );
  }

  return _GraphData(nodes: nodes, edges: edges);
}

// ─── Layout Engine ────────────────────────────────────────────────────────────

void _layoutGraph(_GraphData graph, Size canvasSize) {
  final varNodes = graph.nodes.values
      .where((n) => n.kind == _NodeKind.variable)
      .toList();
  final heapNodes = graph.nodes.values
      .where((n) => n.kind == _NodeKind.heap)
      .toList();
  final nullNodes = graph.nodes.values
      .where((n) => n.kind == _NodeKind.nullNode)
      .toList();

  const nodeW = 110.0;
  const nodeH = 44.0;
  const colGap = 90.0;
  const rowGap = 18.0;

  // Column 1: variable nodes (left)
  double varX = 16.0;
  for (int i = 0; i < varNodes.length; i++) {
    varNodes[i].position = Offset(varX, 16.0 + i * (nodeH + rowGap));
  }

  // Column 2: heap nodes (right center)
  double heapX = varNodes.isNotEmpty ? varX + nodeW + colGap : 16.0;
  for (int i = 0; i < heapNodes.length; i++) {
    heapNodes[i].position = Offset(heapX, 16.0 + i * (nodeH + rowGap));
  }

  // Column 3: null tombstones (rightmost)
  double nullX = heapNodes.isNotEmpty
      ? heapX + nodeW + colGap
      : varX + nodeW + colGap;
  for (int i = 0; i < nullNodes.length; i++) {
    nullNodes[i].position = Offset(nullX, 16.0 + i * (nodeH + rowGap));
  }
}

// ─── Custom Painter ──────────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.graph,
    required this.isDark,
    required this.animValue,
  });

  final _GraphData graph;
  final bool isDark;
  final double animValue;

  static const _accent = Color(0xFF7C4DFF);
  static const _nullColor = Color(0xFFFF4444);
  static const _heapColor = Color(0xFF00C896);

  @override
  void paint(Canvas canvas, Size size) {
    _layoutGraph(graph, size);
    _drawEdges(canvas);
    _drawNodes(canvas);
  }

  void _drawEdges(Canvas canvas) {
    for (final edge in graph.edges) {
      final fromNode = graph.nodes[edge.from];
      final toNode = graph.nodes[edge.to];
      if (fromNode == null || toNode == null) continue;

      final color = edge.isNull ? _nullColor : _accent;
      final paint = Paint()
        ..color = color.withAlpha((animValue * 220).round())
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Start from right-center of from-node, end at left-center of to-node
      final start = Offset(fromNode.rect.right, fromNode.rect.center.dy);
      final end = Offset(toNode.rect.left, toNode.rect.center.dy);

      // Draw bezier curve
      final path = Path();
      path.moveTo(start.dx, start.dy);

      final dx = (end.dx - start.dx).abs();
      final cpOffset = math.max(dx * 0.5, 30.0);
      path.cubicTo(
        start.dx + cpOffset,
        start.dy,
        end.dx - cpOffset,
        end.dy,
        end.dx,
        end.dy,
      );

      // Dashed for null edges
      if (edge.isNull) {
        _drawDashedPath(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }

      // Arrowhead
      _drawArrowhead(canvas, end, color, edge.isNull);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metric = path.computeMetrics().first;
    final total = metric.length;
    double dist = 0;
    const dashLen = 6.0;
    const gapLen = 4.0;
    bool drawing = true;
    while (dist < total) {
      final segEnd = math.min(dist + (drawing ? dashLen : gapLen), total);
      if (drawing) {
        canvas.drawPath(metric.extractPath(dist, segEnd), paint);
      }
      dist = segEnd;
      drawing = !drawing;
    }
  }

  void _drawArrowhead(Canvas canvas, Offset tip, Color color, bool isNull) {
    final paint = Paint()
      ..color = color.withAlpha((animValue * 220).round())
      ..style = PaintingStyle.fill;

    const size = 9.0;
    const angle = math.pi / 6;
    const direction = 0.0; // pointing right

    final p1 = tip;
    final p2 = Offset(
      tip.dx - size * math.cos(direction - angle),
      tip.dy - size * math.sin(direction - angle),
    );
    final p3 = Offset(
      tip.dx - size * math.cos(direction + angle),
      tip.dy - size * math.sin(direction + angle),
    );

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawNodes(Canvas canvas) {
    for (final node in graph.nodes.values) {
      _drawNode(canvas, node);
    }
  }

  void _drawNode(Canvas canvas, _Node node) {
    final rect = node.rect;
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(8));

    Color borderColor;
    Color fillColor;
    Color labelColor;
    Color valueColor;

    switch (node.kind) {
      case _NodeKind.variable:
        borderColor = _accent.withAlpha(160);
        fillColor = isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF0EEFF);
        labelColor = _accent;
        valueColor = isDark ? Colors.white70 : Colors.black87;
        break;
      case _NodeKind.heap:
        final alive = !node.isFree;
        borderColor = alive
            ? _heapColor.withAlpha(160)
            : _nullColor.withAlpha(120);
        fillColor = isDark ? const Color(0xFF151820) : Colors.white;
        labelColor = alive ? _heapColor : _nullColor;
        valueColor = isDark ? Colors.white54 : Colors.black54;
        break;
      case _NodeKind.nullNode:
        borderColor = _nullColor.withAlpha(160);
        fillColor = isDark ? const Color(0xFF200F0F) : const Color(0xFFFFEEEE);
        labelColor = _nullColor;
        valueColor = _nullColor.withAlpha(180);
        break;
    }

    // Shadow
    final shadowPaint = Paint()
      ..color = borderColor.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rr, shadowPaint);

    // Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rr, fillPaint);

    // Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(rr, borderPaint);

    // ── Label (top line) ─────────────────────────────────────────────────────
    final labelPainter = TextPainter(
      text: TextSpan(
        text: node.kind == _NodeKind.nullNode ? '∅ NULL' : node.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: labelColor,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 12);

    final addrText = node.address != null
        ? (TextPainter(
            text: TextSpan(
              text: node.address!,
              style: TextStyle(
                fontSize: 8.5,
                color: isDark ? Colors.white38 : Colors.black38,
                fontFamily: 'monospace',
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: rect.width - 12))
        : null;

    // If we have address, show label + address in header
    if (node.kind == _NodeKind.heap && node.address != null) {
      // Header area (top half)
      final headerH = rect.height * 0.48;
      final headerRect = Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width,
        headerH,
      );
      final hRR = RRect.fromRectAndRadius(headerRect, const Radius.circular(8));
      final headerPaint = Paint()
        ..color = labelColor.withAlpha(20)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(hRR, headerPaint);

      labelPainter.paint(
        canvas,
        Offset(rect.left + 8, rect.top + (headerH - labelPainter.height) / 2),
      );
      addrText?.paint(
        canvas,
        Offset(
          rect.right - (addrText.width + 6),
          rect.top + (headerH - addrText.height) / 2,
        ),
      );

      // Value (bottom half): cell values
      if (node.value.isNotEmpty) {
        final valPainter = TextPainter(
          text: TextSpan(
            text: node.value,
            style: TextStyle(
              fontSize: 9.5,
              color: valueColor,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: rect.width - 12);
        valPainter.paint(
          canvas,
          Offset(
            rect.left + 6,
            rect.top +
                headerH +
                (rect.height - headerH - valPainter.height) / 2,
          ),
        );
      }
    } else {
      // Simple layout: label + value vertically centered
      final valuePainter = TextPainter(
        text: TextSpan(
          text: node.value,
          style: TextStyle(
            fontSize: 10.5,
            color: valueColor,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - 12);

      final totalH =
          labelPainter.height +
          (node.value.isEmpty ? 0 : 3 + valuePainter.height);
      final startY = rect.top + (rect.height - totalH) / 2;

      labelPainter.paint(canvas, Offset(rect.left + 8, startY));

      if (node.value.isNotEmpty) {
        valuePainter.paint(
          canvas,
          Offset(rect.left + 8, startY + labelPainter.height + 3),
        );
      }
    }

    // NULL cross mark
    if (node.kind == _NodeKind.nullNode) {
      final crossPaint = Paint()
        ..color = _nullColor.withAlpha(80)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      const m = 8.0;
      canvas.drawLine(
        Offset(rect.right - m - 8, rect.top + m),
        Offset(rect.right - m + 4, rect.top + m + 12),
        crossPaint,
      );
      canvas.drawLine(
        Offset(rect.right - m + 4, rect.top + m),
        Offset(rect.right - m - 8, rect.top + m + 12),
        crossPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) =>
      old.animValue != animValue || old.isDark != isDark || old.graph != graph;
}

// ─── Main Widget ─────────────────────────────────────────────────────────────

/// Premium pointer graph panel.
///
/// Visualizes pointer relationships between variables and heap blocks.
/// Uses [CustomPainter] for bezier arrow rendering.
class PointerGraphPanel extends ConsumerStatefulWidget {
  const PointerGraphPanel({super.key, required this.isDark});
  final bool isDark;

  @override
  ConsumerState<PointerGraphPanel> createState() => _PointerGraphPanelState();
}

class _PointerGraphPanelState extends ConsumerState<PointerGraphPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stepState = ref.watch(stepNotifierProvider);
    final step = stepState.currentStep;

    final graph = _buildGraph(step);
    _ctrl.forward(from: 0);

    final bgColor = widget.isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final borderColor = widget.isDark
        ? AppColors.darkBorder
        : AppColors.lightBorder;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? AppColors.darkSurface
                  : AppColors.lightSurfaceVariant,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_tree_rounded,
                  size: 14,
                  color: Color(0xFF7C4DFF),
                ),
                const SizedBox(width: 6),
                Text(
                  'Pointer Graph',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: widget.isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _LegendItem(
                  color: const Color(0xFF7C4DFF),
                  label: 'var',
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 8),
                _LegendItem(
                  color: const Color(0xFF00C896),
                  label: 'heap',
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 8),
                _LegendItem(
                  color: const Color(0xFFFF4444),
                  label: 'null',
                  isDark: widget.isDark,
                ),
              ],
            ),
          ),

          // ── Graph canvas ────────────────────────────────────────────────
          Expanded(
            child: graph.isEmpty
                ? const EmptyState(
                    icon: Icons.account_tree_rounded,
                    title: 'No pointer data',
                    message: 'Step through the program to see pointers',
                  )
                : !graph.hasPointers && step?.heap.isEmpty == true
                ? const EmptyState(
                    icon: Icons.link_off_rounded,
                    title: 'No pointers in current scope',
                    message: 'Use int *p = &x; or malloc() to create pointers',
                  )
                : AnimatedBuilder(
                    animation: _anim,
                    builder: (context, _) => CustomPaint(
                      painter: _GraphPainter(
                        graph: graph,
                        isDark: widget.isDark,
                        animValue: _anim.value,
                      ),
                      child: Container(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Legend Item ─────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
  });
  final Color color;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(fontSize: 10, color: color),
        ),
      ],
    );
  }
}

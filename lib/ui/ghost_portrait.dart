import 'dart:math';

import 'package:flutter/material.dart';

import '../game/ghost_costume.dart';
import '../game/halloween_art.dart';

/// Shared, accurately scaled preview for menu, wardrobe and Game Over.
class GhostPortrait extends StatefulWidget {
  const GhostPortrait({
    super.key,
    this.costume = GhostCostume.original,
    this.height = 174,
    this.width = 200,
    this.maxGhostSize = 110,
  });
  final GhostCostume costume;
  final double height, width, maxGhostSize;

  @override
  State<GhostPortrait> createState() => _GhostPortraitState();
}

class _GhostPortraitState extends State<GhostPortrait>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    width: widget.width,
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _PortraitPainter(
          controller,
          widget.costume,
          widget.maxGhostSize,
        ),
      ),
    ),
  );
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.animation, this.costume, this.maxGhostSize)
    : super(repaint: animation);
  final Animation<double> animation;
  final GhostCostume costume;
  final double maxGhostSize;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * pi * 2;
    // Reserve horizontal room for the cape without clipping narrow layouts.
    final s = min(min(size.height * .69, maxGhostSize), size.width / 1.55);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 12),
        width: s * .8 + sin(t) * 8,
        height: 10,
      ),
      Paint()..color = const Color(0x33302247),
    );
    HalloweenArt.ghost(
      canvas,
      Offset((size.width - s) / 2, 13 + sin(t) * 6),
      s,
      t,
      costume: costume,
    );
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter oldDelegate) =>
      oldDelegate.animation != animation ||
      oldDelegate.costume != costume ||
      oldDelegate.maxGhostSize != maxGhostSize;
}

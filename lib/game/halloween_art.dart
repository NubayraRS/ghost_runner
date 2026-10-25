import 'dart:math';
import 'dart:ui';

import 'ghost_costume.dart';

/// Original canvas artwork: no downloaded images or asset loading.
class HalloweenArt {
  // Costume overlays share the original 64-unit ghost coordinate system.
  // Cache their paths/paints; only the cape's canvas transform animates.
  static final _cape = Path()
    ..moveTo(13, 23)
    ..quadraticBezierTo(0, 34, -15, 59)
    ..cubicTo(0, 56, 8, 69, 23, 63)
    ..quadraticBezierTo(32, 59, 41, 63)
    ..cubicTo(56, 69, 64, 57, 79, 59)
    ..quadraticBezierTo(65, 35, 51, 23)
    ..close();
  static final _capeLining = Path()
    ..moveTo(15, 26)
    ..quadraticBezierTo(3, 38, -8, 56)
    ..quadraticBezierTo(9, 61, 22, 59)
    ..quadraticBezierTo(32, 56, 42, 59)
    ..quadraticBezierTo(56, 62, 72, 56)
    ..quadraticBezierTo(61, 38, 49, 26)
    ..close();
  static final _collar = Path()
    ..moveTo(8, 33)
    ..lineTo(-1, 14)
    ..quadraticBezierTo(15, 17, 24, 29)
    ..lineTo(40, 29)
    ..quadraticBezierTo(49, 17, 65, 14)
    ..lineTo(56, 33)
    ..close();
  static final _collarLining = Path()
    ..moveTo(8, 28)
    ..lineTo(3, 18)
    ..lineTo(22, 30)
    ..lineTo(42, 30)
    ..lineTo(61, 18)
    ..lineTo(56, 28)
    ..close();
  static final _fangs = Path()
    ..moveTo(28, 44)
    ..lineTo(31, 45.5)
    ..lineTo(29.8, 49)
    ..close()
    ..moveTo(33, 45.5)
    ..lineTo(36, 44)
    ..lineTo(34.2, 49)
    ..close();
  static final _skeletonSuit = Path()
    ..fillType = PathFillType.evenOdd
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 8, 50, 56),
        const Radius.circular(23),
      ),
    )
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 20, 50, 29),
        const Radius.circular(12),
      ),
    );
  static final _bones = Path()
    ..moveTo(32, 50)
    ..lineTo(32, 61)
    ..moveTo(32, 51)
    ..quadraticBezierTo(25, 48, 21, 51)
    ..moveTo(32, 51)
    ..quadraticBezierTo(39, 48, 43, 51)
    ..moveTo(32, 55)
    ..quadraticBezierTo(26, 52, 22, 54)
    ..moveTo(32, 55)
    ..quadraticBezierTo(38, 52, 42, 54)
    ..moveTo(32, 59)
    ..quadraticBezierTo(27, 56, 24, 58)
    ..moveTo(32, 59)
    ..quadraticBezierTo(37, 56, 40, 58)
    ..moveTo(13, 50)
    ..lineTo(11, 57)
    ..moveTo(51, 50)
    ..lineTo(53, 57)
    ..moveTo(25, 62)
    ..lineTo(25, 65)
    ..moveTo(39, 62)
    ..lineTo(39, 65)
    ..moveTo(25, 14)
    ..lineTo(39, 14);
  static final _capeInk = ink(0xFF292433);
  static final _liningInk = ink(0xFF8C354D);
  static final _suitInk = ink(0xFF34303F);
  static final _boneInk = ink(0xFFFFF8ED)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _fangInk = ink(0xFFFFF8ED);
  static final _fangOutline = ink(0xFF62456C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = .6
    ..strokeJoin = StrokeJoin.round;
  static final _fogPaint = ink(0x128ED7DB);
  static final _starPaint = Paint();
  static final _batPaint = ink(0xFF382C51);
  static final _batPath = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(-12, -14, -22, -5)
    ..lineTo(-14, 4)
    ..lineTo(-7, 2)
    ..lineTo(0, 9)
    ..lineTo(7, 2)
    ..lineTo(14, 4)
    ..lineTo(22, -5)
    ..quadraticBezierTo(12, -14, 0, 0)
    ..close();
  static final _fogPath = Path()
    ..moveTo(-90, 8)
    ..cubicTo(-75, -5, -35, -4, -15, 0)
    ..cubicTo(10, -13, 55, -9, 65, 1)
    ..cubicTo(110, -1, 115, 12, 65, 14)
    ..cubicTo(0, 21, -55, 16, -90, 8)
    ..close();

  static void shieldPickup(Canvas c, double x, double y, double time) {
    c.save();
    c.translate(x + 15, y);
    c.drawCircle(Offset.zero, 18 + sin(time * 3), ink(0x2295F6ED));
    final shape = Path()
      ..moveTo(0, -12)
      ..lineTo(12, -8)
      ..quadraticBezierTo(14, 5, 0, 12)
      ..quadraticBezierTo(-14, 5, -12, -8)
      ..close();
    c.drawPath(shape, ink(0xFF90E5E3));
    c.drawPath(
      shape,
      ink(0xFFE7FFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.drawCircle(const Offset(-4, -2), 1.5, ink(0xFF3B526F));
    c.drawCircle(const Offset(4, -2), 1.5, ink(0xFF3B526F));
    c.drawLine(
      const Offset(-2, 4),
      const Offset(2, 4),
      ink(0xFF3B526F)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    c.restore();
  }

  static void shieldBubble(
    Canvas c,
    Offset center,
    double time, {
    double? burst,
  }) {
    final radius = burst == null ? 37 + sin(time * 3) : 37 + burst * 22;
    c.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF9FF6F2)
            .withValues(alpha: burst == null ? .1 : .12 * (1 - burst)),
    );
    c.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFBAFFF5)
            .withValues(alpha: burst == null ? .7 : 1 - burst)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    if (burst != null) treatPop(c, center, burst * .5);
  }

  static void treat(
    Canvas c,
    double x,
    double y,
    bool chocolate,
    int color, {
    bool golden = false,
    double time = 0,
  }) {
    c.save();
    c.translate(x, y);
    if (golden) {
      c.drawCircle(const Offset(15, 0), 18 + sin(time * 3), ink(0x33FFE18B));
      final spark = Offset(15 + cos(time * 2) * 18, sin(time * 2) * 15);
      final p = ink(0xFFFFF4CB)..strokeWidth = 1.5;
      c.drawLine(spark - const Offset(3, 0), spark + const Offset(3, 0), p);
      c.drawLine(spark - const Offset(0, 3), spark + const Offset(0, 3), p);
    }
    c.drawOval(const Rect.fromLTWH(-3, 9, 36, 7), ink(0x33302247));
    if (chocolate) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(2, -12, 26, 24),
          const Radius.circular(4),
        ),
        ink(0xFF563448),
      );
      for (var row = 0; row < 2; row++) {
        for (var col = 0; col < 3; col++) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(5 + col * 7, -9 + row * 8, 5, 6),
              const Radius.circular(1),
            ),
            ink(0xFFAC735E),
          );
        }
      }
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(1, 2, 28, 11),
          const Radius.circular(3),
        ),
        ink(0xFFBB91DE),
      );
      c.drawCircle(const Offset(15, 7), 3, ink(0xFFFFDB94));
    } else {
      final colors = [0xFFF5A0C5, 0xFF9CE0C4, 0xFFFFC078];
      final paint = ink(golden ? 0xFFFFD451 : colors[color % colors.length]);
      c.drawPath(
        Path()
          ..moveTo(7, 0)
          ..lineTo(0, -9)
          ..lineTo(0, 9)
          ..close(),
        paint,
      );
      c.drawPath(
        Path()
          ..moveTo(23, 0)
          ..lineTo(30, -9)
          ..lineTo(30, 9)
          ..close(),
        paint,
      );
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5, -10, 20, 20),
          const Radius.circular(8),
        ),
        paint,
      );
      c.drawPath(
        Path()
          ..moveTo(11, -7)
          ..quadraticBezierTo(20, -2, 14, 7),
        ink(0xAAFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, -9, 8, 3),
        const Radius.circular(2),
      ),
      ink(0x88FFFFFF),
    );
    c.restore();
  }

  static void treatPop(Canvas c, Offset center, double age) {
    final progress = (age / .5).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = const Color(0xFFFFE4AA).withValues(alpha: 1 - progress)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final angle = i * pi / 3;
      final point =
          center + Offset(cos(angle), sin(angle)) * (6 + progress * 22);
      c.drawLine(point - const Offset(3, 0), point + const Offset(3, 0), paint);
      c.drawLine(point - const Offset(0, 3), point + const Offset(0, 3), paint);
    }
  }

  static Paint ink(int color) => Paint()..color = Color(color);
  static void ghost(
    Canvas c,
    Offset position,
    double size,
    double time, {
    GhostCostume costume = GhostCostume.original,
  }) {
    c.save();
    c.translate(position.dx, position.dy);
    c.scale(size / 64);
    if (costume == GhostCostume.vampire) {
      c.save();
      c.translate(32, 28);
      c.scale(1, 1 + sin(time * 5) * .035);
      c.translate(-32, -28);
      c.drawPath(_cape, _capeInk);
      c.drawPath(_capeLining, _liningInk);
      c.restore();
      c.drawPath(_collar, _capeInk);
      c.drawPath(_collarLining, _liningInk);
    }
    final body = Path()
      ..moveTo(5, 57)
      ..lineTo(5, 29)
      ..cubicTo(5, -5, 59, -5, 59, 29)
      ..lineTo(59, 57)
      ..quadraticBezierTo(53, 66, 46, 56)
      ..quadraticBezierTo(39, 66 + sin(time * 5) * 2, 32, 56)
      ..quadraticBezierTo(25, 66, 18, 56)
      ..quadraticBezierTo(11, 65, 5, 57)
      ..close();
    c.drawShadow(body, const Color(0xFFB49EFF), 10, false);
    c.drawPath(
      body,
      Paint()
        ..shader = Gradient.linear(Offset.zero, const Offset(60, 64), [
          const Color(0xFFFFFFFF),
          const Color(0xFFE7DCFA),
        ]),
    );
    if (costume == GhostCostume.skeleton) {
      c.save();
      c.clipPath(body);
      c.drawPath(_skeletonSuit, _suitInk);
      c.drawPath(_bones, _boneInk);
      // Rounded ends make the forehead bone friendly and readable at small size.
      c.drawCircle(const Offset(25, 14), 1.6, _fangInk);
      c.drawCircle(const Offset(39, 14), 1.6, _fangInk);
      c.restore();
    }
    c.drawOval(const Rect.fromLTWH(14, 25, 12, 17), ink(0xFF302344));
    c.drawOval(const Rect.fromLTWH(38, 25, 12, 17), ink(0xFF302344));
    for (final x in [18.0, 42.0]) {
      c.drawCircle(Offset(x, 29), 3, ink(0xFFFFFFFF));
      c.drawCircle(Offset(x + 4, 36), 1.4, ink(0xFFFFFFFF));
    }
    c.drawOval(const Rect.fromLTWH(8, 41, 13, 7), ink(0xFFF8B4D2));
    c.drawOval(const Rect.fromLTWH(43, 41, 13, 7), ink(0xFFF8B4D2));
    c.drawPath(
      Path()
        ..moveTo(28, 43)
        ..quadraticBezierTo(32, 49, 36, 43),
      ink(0xFF62456C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    if (costume == GhostCostume.vampire) {
      c.drawPath(_fangs, _fangInk);
      c.drawPath(_fangs, _fangOutline);
    }
    c.restore();
  }

  static void pumpkin(Canvas c, double x, double y, double scale) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, -4, 6, 12),
        const Radius.circular(3),
      ),
      ink(0xFF8DAD79),
    );
    c.drawOval(const Rect.fromLTWH(0, 5, 44, 33), ink(0xFFF39A53));
    c.drawOval(const Rect.fromLTWH(9, 5, 27, 33), ink(0xFFFFB563));
    c.drawOval(const Rect.fromLTWH(18, 5, 10, 33), ink(0xFFFFC073));
    for (final dx in [13.0, 30.0]) {
      c.drawCircle(Offset(dx, 21), 2.7, ink(0xFF664060));
    }
    c.drawPath(
      Path()
        ..moveTo(18, 26)
        ..quadraticBezierTo(22, 31, 26, 26),
      ink(0xFF664060)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.restore();
  }

  static void gravestone(Canvas c, double x, double y) {
    c.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, 34, 49),
        topLeft: const Radius.circular(17),
        topRight: const Radius.circular(17),
      ),
      ink(0xFFADA1CD),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 5, y + 6, 24, 36),
        const Radius.circular(11),
      ),
      ink(0xFF8C7FAF),
    );
    final p = ink(0xFFDBD0ED)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(x + 17, y + 14), Offset(x + 17, y + 29), p);
    c.drawLine(Offset(x + 11, y + 20), Offset(x + 23, y + 20), p);
    c.drawOval(Rect.fromLTWH(x - 5, y + 44, 44, 7), ink(0xFF625377));
  }

  static void scene(
    Canvas c,
    Size size,
    double scroll,
    double time, {
    Paint? skyPaint,
  }) {
    final w = size.width, h = size.height;
    final ground = h * .79;
    c.drawRect(
      Offset.zero & size,
      skyPaint ??
          (Paint()
            ..shader = Gradient.linear(
              Offset.zero,
              Offset(0, h),
              [
                const Color(0xFF25203F),
                const Color(0xFF66528C),
                const Color(0xFFB48DBD),
              ],
              [0, .6, 1],
            )),
    );
    final moon = Offset(w * .77, h * .16);
    c.drawCircle(
      moon,
      66,
      Paint()
        ..shader = Gradient.radial(moon, 66, [
          const Color(0x30FFE7B7),
          const Color(0x00FFE7B7),
        ]),
    );
    c.drawCircle(moon, 30, ink(0xFFFFECCD));
    c.drawCircle(moon + const Offset(10, -7), 7, ink(0xFFEBD8BC));
    c.drawCircle(moon + const Offset(-10, 12), 4, ink(0xFFEBD8BC));
    for (var i = 0; i < 38; i++) {
      final x = (i * 79.7 + 19) % w, y = (i * 43.3 + 20) % (ground * .78);
      final p = _starPaint
        ..color = Color.fromRGBO(
          255,
          235,
          217,
          .4 + .3 * sin(time * 1.4 + i).abs(),
        );
      c.drawCircle(Offset(x, y), i % 4 == 0 ? 1.8 : 1, p);
      if (i % 7 == 0) {
        c.drawLine(Offset(x - 4, y), Offset(x + 4, y), p..strokeWidth = 1);
        c.drawLine(Offset(x, y - 4), Offset(x, y + 4), p);
      }
    }
    for (var i = 0; i < 4; i++) {
      final x = (i * 177 + 40 - scroll * .05 - time * 8) % (w + 180) - 90;
      final y = h * .23 + sin(i * 2.0 + time * .7) * 18;
      c.save();
      c.translate(x, y);
      c.scale(.55, .55 + sin(time * 5 + i) * .12);
      c.drawPath(_batPath, _batPaint);
      c.restore();
    }
    for (var layer = 0; layer < 2; layer++) {
      final base = ground + 12 + layer * 12;
      final hill = Path()..moveTo(0, h);
      for (var x = -20.0; x <= w + 20; x += 10) {
        hill.lineTo(
          x,
          base - 35 + sin((x + scroll * (.12 + layer * .12)) / 90) * 23,
        );
      }
      hill
        ..lineTo(w, h)
        ..close();
      c.drawPath(hill, ink(layer == 0 ? 0xFF665380 : 0xFF493C66));
    }
    for (var i = 0; i < 5; i++) {
      final x = (i * 160 - scroll * .2) % 800 - 100, y = ground - 35;
      final p = ink(0xFF3E335A);
      if (i.isEven) {
        c.drawRect(Rect.fromLTWH(x, y - 67, 48, 70), p);
        c.drawPath(
          Path()
            ..moveTo(x - 7, y - 67)
            ..lineTo(x + 24, y - 99)
            ..lineTo(x + 55, y - 67)
            ..close(),
          p,
        );
        c.drawRect(Rect.fromLTWH(x + 34, y - 92, 8, 27), p);
        for (final dx in [10.0, 30.0]) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x + dx, y - 53, 9, 14),
              const Radius.circular(4),
            ),
            ink(0xFFC89883),
          );
        }
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + 19, y - 24, 12, 25),
            const Radius.circular(6),
          ),
          ink(0xFF29243F),
        );
      } else {
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
        c.drawPath(
          Path()
            ..moveTo(x + 25, y + 10)
            ..lineTo(x + 20, y - 80)
            ..moveTo(x + 22, y - 34)
            ..lineTo(x, y - 55)
            ..lineTo(x - 3, y - 76)
            ..moveTo(x + 21, y - 50)
            ..lineTo(x + 42, y - 68)
            ..lineTo(x + 46, y - 90),
          p,
        );
      }
    }
    // Three reusable, low-opacity paths: no blur filters or particle objects.
    for (var i = 0; i < 3; i++) {
      final x = (i * 190 + time * (5 + i)) % (w + 240) - 120;
      c.save();
      c.translate(x, ground - 22 - i * 19 + sin(time * .4 + i) * 4);
      c.scale(1.1 + i * .15, 1);
      c.drawPath(_fogPath, _fogPaint);
      c.restore();
    }
    c.drawRect(Rect.fromLTWH(0, ground, w, h - ground), ink(0xFF30283F));
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-10, ground, w + 20, 9),
        const Radius.circular(4),
      ),
      ink(0xFFB497BF),
    );
    c.drawRect(Rect.fromLTWH(0, ground + 9, w, 8), ink(0xFF655075));
    for (var i = 0; i < 22; i++) {
      final x = (i * 31.0 - scroll) % (w + 40) - 20;
      c.drawOval(
        Rect.fromLTWH(x, ground + 28 + i % 3 * 16, 7, 3),
        ink(0xFF54405E),
      );
    }
    for (var i = 0; i < 4; i++) {
      final x = (i * 153 - scroll * .7) % 612 - 60;
      pumpkin(c, x, ground + 65 + i % 2 * 18, .48);
    }
  }
}

import 'dart:ui';

enum SkyTheme { purple, darkRed, pumpkinOrange }

/// Distance-driven sky. Only rebuilds its shader when colors or size change.
class SkyBackground {
  static const themeIntervalMiles = 500.0;
  // Preserve the existing blend length independently of the theme interval.
  static const transitionMiles = 50.0;
  static const palettes = [
    [Color(0xFF25203F), Color(0xFF66528C), Color(0xFFB48DBD)],
    [Color(0xFF290F20), Color(0xFF6E263D), Color(0xFFB56570)],
    [Color(0xFF321C25), Color(0xFF95502E), Color(0xFFD79858)],
  ];
  static const stops = [0.0, .6, 1.0];
  final _colors = List<Color>.of(palettes.first);
  final _paint = Paint();
  Size? _size;
  bool _dirty = true;
  SkyTheme theme = SkyTheme.purple;
  double _distance = 0;

  Color colorAt(int stop) => _colors[stop];

  void reset() {
    _distance = -1;
    update(0);
  }

  // Expects gameplay miles, never world-space scrolling units or score.
  void update(double distance) {
    if (distance == _distance) return;
    _distance = distance;
    final segment = (distance / themeIntervalMiles).floor();
    final index = segment % SkyTheme.values.length;
    theme = SkyTheme.values[index];
    final t = segment == 0
        ? 1.0
        : ((distance - segment * themeIntervalMiles) / transitionMiles).clamp(
            0.0,
            1.0,
          );
    final blend = t * t * (3 - 2 * t); // Smooth start and finish.
    final previous =
        (index + SkyTheme.values.length - 1) % SkyTheme.values.length;
    for (var i = 0; i < _colors.length; i++) {
      final color = t == 1
          ? palettes[index][i]
          : Color.lerp(palettes[previous][i], palettes[index][i], blend)!;
      if (_colors[i] != color) {
        _colors[i] = color;
        _dirty = true;
      }
    }
  }

  Paint paintFor(Size size) {
    if (_dirty || _size != size) {
      _paint.shader = Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        _colors,
        stops,
      );
      _size = size;
      _dirty = false;
    }
    return _paint;
  }
}

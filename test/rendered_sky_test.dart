import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/ghost_runner_game.dart';
import 'package:ghost_runner/game/runner_model.dart';
import 'package:ghost_runner/game/sky_background.dart';

// Read actual pixels from the complete Flame renderer, not its theme enum.
Future<List<int>> skyPixel(
  void Function(ui.Canvas) render, {
  int width = 400,
  int height = 800,
}) async {
  final recorder = ui.PictureRecorder();
  render(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  // The upper sky is clear of moon, stars, scenery and HUD at this location.
  final offset = ((height ~/ 80) * width + width ~/ 2) * 4;
  final pixel = List<int>.generate(4, (i) => bytes.getUint8(offset + i));
  image.dispose();
  picture.dispose();
  return pixel;
}

Future<List<int>> palettePixel(
  List<ui.Color> colors, {
  int width = 400,
  int height = 800,
}) => skyPixel(
  (canvas) {
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset.zero,
          ui.Offset(0, height.toDouble()),
          colors,
          SkyBackground.stops,
        ),
    );
  },
  width: width,
  height: height,
);

void main() {
  testWidgets(
    'Rendered sky follows HUD miles, not scroll, score or animation time',
    (tester) async {
      final game = GhostRunnerGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      game.pauseEngine();
      game.onGameResize(Vector2(400, 800));
      game.start();
      game.model.spawnIn = game.model.treatSpawnIn = 10000;

      // Reproduce the old runtime problem: >500 world units after ~3 seconds,
      // but only ~30 real miles. The entire rendered sky must remain purple.
      for (var i = 0; i < 360; i++) {
        game.update(1 / 120);
      }
      expect(game.model.distance, greaterThan(500));
      expect(game.miles.value, inInclusiveRange(30, 31));
      final purple = await tester.runAsync(
        () => palettePixel(SkyBackground.palettes[0]),
      );
      expect(await tester.runAsync(() => skyPixel(game.render)), purple);

      final samples = {
        0.0: 0, 100.0: 0, 499.0: 0, 499.99: 0,
        500.0: 0, // Transition starts here, from unchanged purple.
        550.0: 1, 900.0: 1, 999.99: 1,
        1000.0: 1, // Transition starts here, from unchanged red.
        1050.0: 2, 1400.0: 2, 1499.99: 2,
        1500.0: 2, 1550.0: 0,
      };
      for (final sample in samples.entries) {
        game.model.distance = sample.key * RunnerModel.worldUnitsPerMile;
        game.animationTime = sample.key * 100; // Cannot drive color changes.
        game.update(0);
        expect(game.miles.value, sample.key.floor());
        final expected = await tester.runAsync(
          () => palettePixel(SkyBackground.palettes[sample.value]),
        );
        expect(
          await tester.runAsync(() => skyPixel(game.render)),
          expected,
          reason: 'Wrong rendered sky at ${sample.key} miles',
        );
      }
      // Verify actual interpolated pixels, not just smooth color model values.
      game.model.distance = 525 * RunnerModel.worldUnitsPerMile;
      game.update(0);
      final halfway = List<ui.Color>.generate(
        3,
        (i) => ui.Color.lerp(
          SkyBackground.palettes[0][i],
          SkyBackground.palettes[1][i],
          .5,
        )!,
      );
      expect(
        await tester.runAsync(() => skyPixel(game.render)),
        await tester.runAsync(() => palettePixel(halfway)),
      );

      game.model.distance = 499 * RunnerModel.worldUnitsPerMile;
      final candy = Treat(100, 25, TreatKind.golden);
      game.model.treats.add(candy);
      game.model.collect(candy);
      game.model.bonusScore += 5000;
      game.update(0);
      expect(game.model.score, greaterThan(5000));
      expect(game.miles.value, 499);
      expect(await tester.runAsync(() => skyPixel(game.render)), purple);

      // Layout changes must preserve the selected sky shader as well.
      game.onGameResize(Vector2(800, 1600));
      game.update(0);
      expect(
        await tester.runAsync(
          () => skyPixel(game.render, width: 800, height: 1600),
        ),
        await tester.runAsync(
          () =>
              palettePixel(SkyBackground.palettes[0], width: 800, height: 1600),
        ),
      );
      game.model.distance = 1100 * RunnerModel.worldUnitsPerMile;
      game.update(0);
      game.start();
      expect(game.miles.value, 0);
      expect(
        await tester.runAsync(
          () => skyPixel(game.render, width: 800, height: 1600),
        ),
        await tester.runAsync(
          () =>
              palettePixel(SkyBackground.palettes[0], width: 800, height: 1600),
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

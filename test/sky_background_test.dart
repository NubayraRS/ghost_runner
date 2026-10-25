import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/ghost_runner_game.dart';
import 'package:ghost_runner/game/runner_model.dart';
import 'package:ghost_runner/game/sky_background.dart';

void main() {
  const boundaries = {
    0: SkyTheme.purple,
    99: SkyTheme.purple,
    100: SkyTheme.purple,
    400: SkyTheme.purple,
    499: SkyTheme.purple,
    500: SkyTheme.darkRed,
    999: SkyTheme.darkRed,
    1000: SkyTheme.pumpkinOrange,
    1499: SkyTheme.pumpkinOrange,
    1500: SkyTheme.purple,
    1999: SkyTheme.purple,
    2000: SkyTheme.darkRed,
    2499: SkyTheme.darkRed,
    2500: SkyTheme.pumpkinOrange,
    2999: SkyTheme.pumpkinOrange,
    3000: SkyTheme.purple,
  };
  for (final entry in boundaries.entries) {
    test('Distance ${entry.key} selects ${entry.value}', () {
      final sky = SkyBackground()..update(entry.key.toDouble());
      expect(sky.theme, entry.value);
      // At the threshold the new theme starts from the previous palette.
      final index = entry.value.index;
      final palette = entry.key > 0 && entry.key % 500 == 0
          ? (index + 2) % 3
          : index;
      for (var i = 0; i < 3; i++) {
        expect(sky.colorAt(i), SkyBackground.palettes[palette][i]);
      }
    });
  }
  for (final threshold in [500.0, 1000.0, 1500.0, 2000.0, 2500.0, 3000.0]) {
    test('Smooth, continuous palette blend at $threshold', () {
      final sky = SkyBackground()..update(threshold - .001);
      final before = List.generate(3, sky.colorAt);
      sky.update(threshold);
      expect(List.generate(3, sky.colorAt), before);
      final next = (threshold / 500).floor() % 3;
      sky.update(threshold + SkyBackground.transitionMiles / 2);
      for (var i = 0; i < 3; i++) {
        expect(
          sky.colorAt(i),
          Color.lerp(before[i], SkyBackground.palettes[next][i], .5),
        );
      }
      sky.update(threshold + SkyBackground.transitionMiles);
      expect(List.generate(3, sky.colorAt), SkyBackground.palettes[next]);
    });
  }
  test(
    'Shader and paint are reused when settled; resizing refreshes shader',
    () {
      final sky = SkyBackground()..update(560);
      const size = Size(400, 800);
      final paint = sky.paintFor(size);
      final shader = paint.shader;
      sky.update(561);
      expect(identical(sky.paintFor(size), paint), isTrue);
      expect(identical(paint.shader, shader), isTrue);
      sky.paintFor(const Size(400, 900));
      expect(identical(paint.shader, shader), isFalse);
    },
  );
  testWidgets('Game uses distance rather than elapsed score or treat bonuses', (
    tester,
  ) async {
    final game = GhostRunnerGame();
    await tester.pumpWidget(GameWidget(game: game));
    await tester.runAsync(() => game.loaded);
    await tester.pump();
    game.pauseEngine();
    game.start();
    game.model.distance = 499 * RunnerModel.worldUnitsPerMile;
    game.model.elapsed = 100;
    final treat = Treat(100, 25, TreatKind.chocolate);
    game.model.treats.add(treat);
    game.model.collect(treat);
    game.update(0);
    expect(game.model.score, 1010);
    expect(game.sky.theme, SkyTheme.purple);
    game.model.distance = 500 * RunnerModel.worldUnitsPerMile;
    game.update(0);
    expect(game.sky.theme, SkyTheme.darkRed);
    game.model.distance = 1060 * RunnerModel.worldUnitsPerMile;
    game.update(0);
    expect(game.sky.colorAt(0), SkyBackground.palettes[2][0]);
    game.start();
    expect(game.model.distance, 0);
    expect(game.sky.theme, SkyTheme.purple);
    expect(List.generate(3, game.sky.colorAt), SkyBackground.palettes[0]);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

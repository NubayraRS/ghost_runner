import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/ghost_costume.dart';
import 'package:ghost_runner/game/ghost_runner_game.dart';
import 'package:ghost_runner/game/halloween_art.dart';
import 'package:ghost_runner/game/wardrobe_store.dart';

Future<Uint8List> raster(
  void Function(ui.Canvas) draw,
  int width,
  int height,
) async {
  final recorder = ui.PictureRecorder();
  draw(ui.Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final bytes = Uint8List.fromList(data.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return bytes;
}

Future<Uint8List> ghost(GhostCostume? costume) => raster(
  (canvas) {
    if (costume == null) {
      HalloweenArt.ghost(canvas, const ui.Offset(48, 32), 128, .75);
    } else {
      HalloweenArt.ghost(
        canvas,
        const ui.Offset(48, 32),
        128,
        .75,
        costume: costume,
      );
    }
  },
  224,
  192,
);

List<int> pixel(Uint8List bytes, int x, int y) =>
    bytes.sublist((y * 224 + x) * 4, (y * 224 + x) * 4 + 4);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Original defaults to unchanged white ghost; costumes preserve the face',
    () async {
      final original = await ghost(GhostCostume.original);
      expect(await ghost(null), orderedEquals(original));
      final vampire = await ghost(GhostCostume.vampire);
      final skeleton = await ghost(GhostCostume.skeleton);
      expect(vampire, isNot(orderedEquals(original)));
      expect(skeleton, isNot(orderedEquals(original)));
      expect(skeleton, isNot(orderedEquals(vampire)));
      // Every eye/facial-proportion pixel in the open face remains identical.
      for (var y = 25; y < 42; y++) {
        for (var x = 13; x < 51; x++) {
          final expected = pixel(original, 48 + x * 2, 32 + y * 2);
          expect(pixel(vampire, 48 + x * 2, 32 + y * 2), expected);
          expect(pixel(skeleton, 48 + x * 2, 32 + y * 2), expected);
        }
      }
      for (final x in [14, 49]) {
        expect(
          pixel(skeleton, 48 + x * 2, 120),
          pixel(original, 48 + x * 2, 120),
        );
      }
      expect(
        pixel(vampire, 40, 140)[3],
        greaterThan(pixel(original, 40, 140)[3]),
      );
      expect(pixel(skeleton, 82, 138)[0], lessThan(100)); // Charcoal suit.
      expect(pixel(skeleton, 112, 140)[0], greaterThan(220)); // White spine.
      expect(
        pixel(vampire, 108, 126),
        isNot(pixel(original, 108, 126)),
      ); // Fang.
    },
  );

  testWidgets(
    'Live game renderer changes costumes, also when jumping/shielded',
    (tester) async {
      final wardrobe = WardrobeStore.memory();
      final game = GhostRunnerGame(wardrobe: wardrobe);
      await tester.pumpWidget(GameWidget(game: game));
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      game.pauseEngine();
      game.onGameResize(Vector2(400, 800));
      game.start();
      game.model.spawnIn = game.model.treatSpawnIn = 10000;
      for (final shielded in [false, true]) {
        game.model.shieldActive = shielded;
        game.model.jumpHeight = shielded ? 70 : 0;
        final pictures = <Uint8List>[];
        for (final costume in GhostCostume.values) {
          await wardrobe.select(costume);
          game.update(0);
          pictures.add(
            (await tester.runAsync(() => raster(game.render, 400, 800)))!,
          );
        }
        expect(pictures[0], isNot(orderedEquals(pictures[1])));
        expect(pictures[0], isNot(orderedEquals(pictures[2])));
        expect(pictures[1], isNot(orderedEquals(pictures[2])));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      wardrobe.dispose();
    },
  );
}

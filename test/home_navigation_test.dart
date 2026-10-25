import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/best_score_store.dart';
import 'package:ghost_runner/game/game_audio.dart';
import 'package:ghost_runner/game/ghost_costume.dart';
import 'package:ghost_runner/game/ghost_runner_game.dart';
import 'package:ghost_runner/game/runner_model.dart';
import 'package:ghost_runner/game/sky_background.dart';
import 'package:ghost_runner/game/wardrobe_store.dart';
import 'package:ghost_runner/main.dart';
import 'package:ghost_runner/ui/ghost_portrait.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sound_backend.dart';

void expectIdle(GhostRunnerGame game) {
  expect(game.model.phase, RunPhase.menu);
  expect(game.model.score, 0);
  expect(game.model.distance, 0);
  expect(game.model.jumpHeight, 0);
  expect(game.model.velocity, 0);
  expect(game.model.obstacles, isEmpty);
  expect(game.model.treats, isEmpty);
  expect(game.model.pops, isEmpty);
  expect(game.model.treatsCollected, 0);
  expect(game.model.shieldActive, isFalse);
  expect(game.model.shieldBurstRemaining, 0);
  expect(game.model.lastMilestone, 0);
  expect(game.model.milestoneRemaining, 0);
  expect(game.model.celebrationRemaining, 0);
  expect(game.score.value, 0);
  expect(game.miles.value, 0);
  expect(game.milestone.value, 0);
  expect(game.shieldActive.value, isFalse);
  expect(game.sky.theme, SkyTheme.purple);
}

void main() {
  for (final size in [const Size(320, 568), const Size(1100, 800)]) {
    for (final fromPause in [false, true]) {
      testWidgets(
        '${fromPause ? "Pause" : "Game Over"} → Home → Play at $size',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({
            BestScoreStore.storageKey: 10,
            WardrobeStore.storageKey: 'vampire',
          });
          final best = await BestScoreStore.load();
          final wardrobe = await WardrobeStore.load();
          final backend = FakeSoundBackend();
          final audio = await GameAudio.load(backend: backend);
          await tester.pumpWidget(
            GhostRunnerApp(bestScore: best, wardrobe: wardrobe, audio: audio),
          );
          await tester.pump();
          final game = tester
              .widget<GameWidget<GhostRunnerGame>>(
                find.byType(GameWidget<GhostRunnerGame>),
              )
              .game!;
          await tester.runAsync(() => game.loaded);
          await tester.pump();
          await tester.ensureVisible(find.text('Play'));
          await tester.tap(find.text('Play'));
          await tester.pump();
          await audio.settled;
          game.model.spawnIn = game.model.treatSpawnIn = 10000;
          final golden = Treat(100, 25, TreatKind.golden);
          game.model.treats.add(golden);
          game.model.collect(golden);
          game.model.distance = 600 * RunnerModel.worldUnitsPerMile;
          game.update(0);
          game.model.treats.add(Treat(350, 100, TreatKind.candy));
          game.update(0);
          game.update(0); // Mount a real collectible hitbox to clean up.
          if (fromPause) {
            await tester.tap(find.byTooltip('Pause'));
            await tester.pump();
            expect(find.text('Paused'), findsOneWidget);
          } else {
            game.model.obstacles.add(Obstacle(100, true));
            game.update(.01);
            await tester.pump();
            expect(find.text('Game Over'), findsOneWidget);
            expect(find.text('Restart'), findsOneWidget);
            expect(
              tester.getTopLeft(find.text('Home')).dy,
              greaterThan(tester.getTopLeft(find.text('Restart')).dy),
            );
          }
          // Exercise both mute settings without affecting navigation or storage.
          final enabled = !fromPause;
          await audio.setEnabled(enabled);
          await tester.ensureVisible(find.text('Home'));
          await tester.tap(find.text('Home'));
          await tester.pump();
          await audio.settled;
          expect(find.text('Wardrobe'), findsOneWidget);
          expect(find.text('Game Over'), findsNothing);
          expect(find.text('Paused'), findsNothing);
          expect(find.text('BEST SCORE  25'), findsOneWidget);
          expect(
            tester.widget<GhostPortrait>(find.byType(GhostPortrait)).costume,
            GhostCostume.vampire,
          );
          expectIdle(game);
          final plays = backend.played.length;
          final stopCount = backend.stops;
          expect(stopCount, greaterThan(0));
          for (var i = 0; i < 60; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          await audio.settled;
          expectIdle(game);
          expect(backend.played.length, plays);
          expect(
            game.children
                .whereType<PositionComponent>()
                .whereType<CollisionCallbacks>(),
            isEmpty,
          );
          expect(game.wardrobe.value, GhostCostume.vampire);
          expect(audio.value, enabled);
          await best.record(25);
          expect((await BestScoreStore.load()).value, 25);
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString(WardrobeStore.storageKey), 'vampire');
          expect(prefs.getBool(GameAudio.storageKey) ?? true, enabled);
          await tester.ensureVisible(find.text('Play'));
          await tester.tap(find.text('Play'));
          await tester.pump();
          expect(game.model.phase, RunPhase.running);
          expect(game.model.score, 0);
          expect(game.model.shieldActive, isFalse);
          expect(game.model.obstacles, isEmpty);
          expect(game.wardrobe.value, GhostCostume.vampire);
          game.model.jump();
          await tester.pump(const Duration(milliseconds: 80));
          await audio.settled;
          expect(game.model.jumpHeight, greaterThan(0));
          if (enabled) expect(backend.played.length, greaterThan(plays));
          // The existing Restart action remains usable with Home beside it.
          game.model.jumpHeight = game.model.velocity = 0;
          game.model.obstacles.add(Obstacle(100, false));
          game.update(.01);
          await tester.pump();
          await tester.ensureVisible(find.text('Restart'));
          await tester.tap(find.text('Restart'));
          await tester.pump();
          expect(game.model.phase, RunPhase.running);
          expect(game.model.score, 0);
          expect(game.wardrobe.value, GhostCostume.vampire);
          await tester.pumpWidget(const SizedBox.shrink());
          await audio.settled;
          best.dispose();
          wardrobe.dispose();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

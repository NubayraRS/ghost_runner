import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/ghost_costume.dart';
import 'package:ghost_runner/game/ghost_runner_game.dart';
import 'package:ghost_runner/game/runner_model.dart';
import 'package:ghost_runner/game/wardrobe_store.dart';

void main() {
  for (final costume in GhostCostume.values) {
    test(
      '${costume.label} preserves physics, hitboxes, scoring and restart',
      () async {
        final wardrobe = WardrobeStore.memory(selected: costume);
        final game = GhostRunnerGame(wardrobe: wardrobe);
        final control = RunnerModel();
        game.start();
        control.start();
        for (final model in [game.model, control]) {
          model.spawnIn = model.treatSpawnIn = 10000;
          for (final kind in [
            TreatKind.candy,
            TreatKind.chocolate,
            TreatKind.golden,
            TreatKind.shield,
          ]) {
            final treat = Treat(100, 25, kind);
            model.treats.add(treat);
            model.collect(treat);
          }
          model.obstacles.add(Obstacle(175, true));
          model.jump();
        }
        for (var i = 0; i < 120; i++) {
          game.model.update(1 / 120);
          control.update(1 / 120);
          expect(game.model.ghostBounds(632), control.ghostBounds(632));
          expect(game.model.jumpHeight, control.jumpHeight);
          expect(game.model.velocity, control.velocity);
          expect(game.model.speed, control.speed);
          expect(game.model.distance, control.distance);
          expect(game.model.score, control.score);
          expect(game.model.phase, control.phase);
        }
        expect(game.model.bonusScore, 40);
        expect(game.model.treatsCollected, 3);
        expect(game.model.shieldActive, isTrue);
        game.model.obstacles.add(Obstacle(100, false));
        game.model.update(1 / 120);
        expect(game.model.shieldActive, isFalse);
        expect(game.model.phase, RunPhase.running);
        game.model.obstacles.add(Obstacle(100, true));
        game.model.update(1 / 120);
        expect(game.model.phase, RunPhase.gameOver);
        expect(game.wardrobe.value, costume);
        game.start();
        expect(game.wardrobe.value, costume);
        expect(game.model.score, 0);
        expect(game.model.shieldActive, isFalse);
        expect(game.model.ghostBounds(632), RunnerModel().ghostBounds(632));
        game.audio.dispose();
        await game.audio.settled;
        wardrobe.dispose();
      },
    );
  }
}

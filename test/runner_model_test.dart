import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/runner_model.dart';

void advance(RunnerModel model, double seconds) {
  for (var i = 0; i < (seconds * 120).round(); i++) {
    model.update(1 / 120);
  }
}

void main() {
  for (final kind in TreatKind.values) {
    for (final dt in [1 / 120, 1 / 30, .5, 5.0]) {
      test('Obstacle spawn preserves visible $kind at dt=$dt', () {
        final model = RunnerModel()..start();
        final treat = Treat(350, 100, kind);
        model.treats.add(treat);
        model.spawnIn = 0;
        model.treatSpawnIn = 100;
        model.update(dt);
        expect(model.treats, contains(same(treat)));
        expect(model.treatsCollected, 0);
        expect(model.bonusScore, 0);
        expect(model.pops, isEmpty);
        expect(model.safeTreatPosition(treat.x), isTrue);
        // Once the treat has passed, obstacle spawning can resume.
        advance(model, 1);
        expect(model.obstacles, isNotEmpty);
        expect(model.treats, contains(same(treat)));
      });
    }
  }
  test('Collection rejects a stale collision without genuine contact', () {
    final model = RunnerModel()..start();
    final treat = Treat(350, 25, TreatKind.chocolate);
    model.treats.add(treat);
    model.collect(treat);
    expect(model.treats, contains(same(treat)));
    expect(model.bonusScore, 0);
    expect(model.treatsCollected, 0);
  });
  for (final kind in TreatKind.values) {
    test('$kind stays until fully off-screen without awarding points', () {
      final model = RunnerModel()..start();
      model.spawnIn = model.treatSpawnIn = 100;
      final treat = Treat(-10, 100, kind);
      model.treats.add(treat);
      model.update(1 / 120);
      expect(treat.x + 30, greaterThan(0));
      expect(model.treats, contains(same(treat)));
      advance(model, .3);
      expect(treat.x + 33, lessThan(0)); // Includes the artwork's shadow.
      expect(model.treats, isEmpty);
      expect(model.treatsCollected, 0);
      expect(model.bonusScore, 0);
    });
    test('Long frame substeps collect $kind exactly once', () {
      final model = RunnerModel()..start();
      model.spawnIn = model.treatSpawnIn = 100;
      model.elapsed = 60; // Maximum running speed.
      final treat = Treat(125, 25, kind);
      model.treats.add(treat);
      model.update(5);
      model.collect(treat);
      expect(model.elapsed, closeTo(60.1, .00001));
      expect(model.treats, isEmpty);
      expect(model.treatsCollected, kind == TreatKind.shield ? 0 : 1);
      expect(model.bonusScore, treat.points);
      expect(model.pops, hasLength(1));
    });
  }
  for (final kind in TreatKind.values) {
    test('$kind awards points once on contact', () {
      final model = RunnerModel()..start();
      final treat = Treat(100, 25, kind);
      model.treats.add(treat);
      model.update(1 / 120);
      expect(model.treats, isEmpty);
      expect(model.treatsCollected, kind == TreatKind.shield ? 0 : 1);
      expect(model.bonusScore, switch (kind) {
        TreatKind.chocolate => 10,
        TreatKind.candy => 5,
        TreatKind.golden => 25,
        TreatKind.shield => 0,
      });
      model.collect(treat);
      expect(model.treatsCollected, kind == TreatKind.shield ? 0 : 1);
      expect(model.pops, hasLength(1));
      advance(model, .6);
      expect(model.pops, isEmpty);
      expect(model.score, (model.elapsed * 10).floor() + treat.points);
    });
  }
  test('Airborne treats require a jump and missed treats leave the world', () {
    final model = RunnerModel()..start();
    model.treats.add(Treat(100, 100, TreatKind.candy));
    model.update(1 / 120);
    expect(model.treatsCollected, 0);
    model.jumpHeight = 80;
    model.update(1 / 120);
    expect(model.treatsCollected, 1);
    model.treats.add(Treat(-39, 100, TreatKind.candy));
    model.update(.02);
    expect(model.treats, isEmpty);
  });
  test('Fifth treat celebrates briefly and restart resets all treat state', () {
    final model = RunnerModel()..start();
    for (var i = 0; i < 5; i++) {
      model.treats.add(Treat(100, 25, TreatKind.candy));
      model.update(1 / 120);
    }
    expect(model.treatsCollected, 5);
    expect(model.bonusScore, 25);
    expect(model.celebrationRemaining, greaterThan(0));
    model.obstacles.clear();
    model.spawnIn = 100;
    advance(model, 2.1);
    expect(model.celebrationRemaining, 0);
    model.start();
    expect(model.treatsCollected, 0);
    expect(model.bonusScore, 0);
    expect(model.treats, isEmpty);
    expect(model.pops, isEmpty);
    expect(model.celebrationRemaining, 0);
  });
  test('Spawned treats stay reachable with generous obstacle clearance', () {
    final model = RunnerModel(random: Random(32))..start();
    var spawned = false;
    for (var i = 0; i < 3600; i++) {
      // Keep running to exercise spawning at increasing speeds.
      model.obstacles.removeWhere((o) => o.x < 150);
      model.update(1 / 120);
      for (final treat in model.treats) {
        spawned = true;
        expect(treat.height, anyOf(25, 100));
        expect(model.safeTreatPosition(treat.x), isTrue);
      }
    }
    expect(spawned, isTrue);
  });
  test('Game over prevents collection and freezes totals', () {
    final model = RunnerModel()..start();
    final treat = Treat(100, 25, TreatKind.chocolate);
    model.treats.add(treat);
    model.phase = RunPhase.gameOver;
    model.collect(treat);
    model.update(.1);
    expect(model.score, 0);
    expect(model.treatsCollected, 0);
  });
  test('Menu is idle; start begins survival scoring', () {
    final model = RunnerModel(random: Random(1));
    advance(model, 1);
    expect(model.score, 0);
    model.start();
    advance(model, 1);
    expect(model.score, inInclusiveRange(9, 10));
    expect(model.distance, greaterThan(180));
  });
  test('Jump rises, rejects double jumps, and lands', () {
    final model = RunnerModel()
      ..start()
      ..jump();
    advance(model, .2);
    expect(model.jumpHeight, greaterThan(60));
    final velocity = model.velocity;
    model.jump();
    expect(model.velocity, velocity);
    advance(model, .6);
    expect(model.grounded, isTrue);
    expect(model.velocity, 0);
    model.jump();
    expect(model.velocity, greaterThan(0));
  });
  for (final pumpkin in [true, false]) {
    test(
      '${pumpkin ? "Pumpkin" : "Gravestone"} collision stops score and restart clears state',
      () {
        final model = RunnerModel()..start();
        model.obstacles.add(Obstacle(120, pumpkin));
        advance(model, .3);
        expect(model.phase, RunPhase.gameOver);
        final score = model.score;
        advance(model, 2);
        expect(model.score, score);
        model.start();
        expect(model.phase, RunPhase.running);
        expect(model.obstacles, isEmpty);
        expect(model.score, 0);
        expect(model.jumpHeight, 0);
        expect(model.spawnIn, 1.6);
      },
    );
    test('A timed jump clears ${pumpkin ? "pumpkin" : "gravestone"}', () {
      final model = RunnerModel()..start();
      model.obstacles.add(Obstacle(175, pumpkin));
      model.jump();
      advance(model, .85);
      expect(model.phase, RunPhase.running);
      expect(model.grounded, isTrue);
    });
  }
  test('Obstacles spawn with a safe initial runway', () {
    final model = RunnerModel(random: Random(8))..start();
    // Isolate the initial obstacle timer from treat clearance deferrals.
    model.treatSpawnIn = 100;
    advance(model, 1.5);
    expect(model.obstacles, isEmpty);
    advance(model, .2);
    expect(model.obstacles, hasLength(1));
    expect(model.obstacles.first.x, greaterThan(390));
    expect(model.spawnIn, greaterThan(1.2));
  });
}

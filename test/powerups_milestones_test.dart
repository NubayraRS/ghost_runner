import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/runner_model.dart';
import 'package:ghost_runner/game/sky_background.dart';

RunnerModel runner() {
  final model = RunnerModel()..start();
  model.spawnIn = model.treatSpawnIn = 10000;
  return model;
}

void advance(RunnerModel model, double seconds) {
  for (var i = 0; i < (seconds * 120).round(); i++) {
    model.update(1 / 120);
  }
}

void pickup(RunnerModel model, TreatKind kind) {
  final treat = Treat(100, 25, kind);
  model.treats.add(treat);
  model.collect(treat);
  model.collect(treat); // Repeated Flame/substep callbacks must be harmless.
}

void main() {
  for (final distance in [
    99.0,
    100.0,
    199.0,
    200.0,
    299.0,
    300.0,
    400.0,
    499.0,
    500.0,
    600.0,
    700.0,
    800.0,
    900.0,
    1000.0,
    1500.0,
  ]) {
    test('Milestone at $distance uses the same distance as the sky', () {
      final model = runner()
        ..distance = distance * RunnerModel.worldUnitsPerMile;
      model.update(0);
      final highest = (distance / 100).floor() * 100;
      expect(model.lastMilestone, highest);
      expect(model.activeMilestone, highest == 0 ? 0 : 100);
      final sky = SkyBackground()..update(model.miles);
      expect(sky.theme.index, (distance / 500).floor() % 3);
      final remaining = model.milestoneRemaining;
      model.update(0);
      expect(model.milestoneRemaining, remaining);
    });
  }
  test('Crossed milestones queue exactly once and each lasts 1.8 seconds', () {
    final model = runner()..distance = 99 * RunnerModel.worldUnitsPerMile;
    model.update(0);
    pickup(model, TreatKind.golden);
    expect(model.lastMilestone, 0);
    model.distance = 305 * RunnerModel.worldUnitsPerMile; // Multiple thresholds skipped by a single update.
    model.update(0);
    expect(model.lastMilestone, 300);
    expect(model.activeMilestone, 100);
    // Hold distance fixed to isolate banner timing from further milestones.
    for (final milestone in [100, 200, 300]) {
      expect(model.activeMilestone, milestone);
      for (var i = 0; i < 17; i++) {
        model.distance = 305 * RunnerModel.worldUnitsPerMile;
        model.update(.1);
      }
      expect(model.activeMilestone, milestone);
      model.distance = 305 * RunnerModel.worldUnitsPerMile;
      model.update(.1);
      model.distance = 305 * RunnerModel.worldUnitsPerMile;
      model.update(.01); // Allow for substep rounding at the duration boundary.
    }
    expect(model.activeMilestone, 0);
    model.distance = 305 * RunnerModel.worldUnitsPerMile;
    model.update(0);
    expect(model.activeMilestone, 0);
    model.start();
    expect(model.lastMilestone, 0);
    expect(model.activeMilestone, 0);
  });
  test('Long dt crosses a threshold without teleporting or missing it', () {
    final model = runner()..distance = 99 * RunnerModel.worldUnitsPerMile;
    model.update(5);
    expect(model.miles, inExclusiveRange(100, 101));
    expect(model.lastMilestone, 100);
    expect(model.activeMilestone, 100);
  });
  test('Shield absorbs one obstacle and never re-hits that obstacle', () {
    final model = runner();
    pickup(model, TreatKind.shield);
    expect(model.shieldActive, isTrue);
    expect(model.bonusScore, 0);
    expect(model.treatsCollected, 0);
    final obstacle = Obstacle(100, true);
    model.obstacles.add(obstacle);
    model.update(1 / 120);
    expect(model.phase, RunPhase.running);
    expect(model.shieldActive, isFalse);
    expect(obstacle.shieldAbsorbed, isTrue);
    expect(model.shieldBurstRemaining, greaterThan(0));
    model.update(.05);
    expect(model.phase, RunPhase.running);
    expect(model.ghostBounds(0).overlaps(obstacle.bounds(0)), isTrue);
    model.obstacles.add(Obstacle(100, false));
    model.update(1 / 120);
    expect(model.phase, RunPhase.gameOver);
    expect(model.shieldActive, isFalse);
    model.start();
    expect(model.shieldActive, isFalse);
    expect(model.shieldBurstRemaining, 0);
    expect(model.obstacles, isEmpty);
  });
  test('Shield is not stacked, and non-running updates freeze powerups', () {
    final model = runner();
    pickup(model, TreatKind.shield);
    pickup(model, TreatKind.shield);
    model.update(0);
    final elapsed = model.elapsed;
    expect(model.shieldActive, isTrue);
    expect(model.elapsed, elapsed);
    model.obstacles.addAll([Obstacle(100, true), Obstacle(100, false)]);
    model.update(1 / 120);
    expect(model.phase, RunPhase.gameOver);
    final score = model.score;
    model.update(5);
    expect(model.score, score);
    pickup(model, TreatKind.shield);
    expect(model.shieldActive, isFalse);
  });
  test('Golden candy and shields spawn much less often than normal treats', () {
    final model = RunnerModel(random: Random(41))..start();
    model.spawnIn = 10000;
    final counts = {for (final kind in TreatKind.values) kind: 0};
    for (var i = 0; i < 1000; i++) {
      model.treats.clear();
      model.treatSpawnIn = 0;
      model.update(1 / 120);
      counts[model.treats.single.kind] = counts[model.treats.single.kind]! + 1;
    }
    for (final rare in [TreatKind.golden, TreatKind.shield]) {
      expect(counts[rare], greaterThan(0));
      expect(counts[rare], lessThan(counts[TreatKind.candy]!));
      expect(counts[rare], lessThan(counts[TreatKind.chocolate]!));
    }
  });
}

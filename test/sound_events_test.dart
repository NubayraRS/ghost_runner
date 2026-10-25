import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/runner_model.dart';
import 'package:ghost_runner/game/sound_effect.dart';

RunnerModel runWithSounds(List<SoundEffect> sounds) {
  final model = RunnerModel()..onSound = sounds.add;
  model.start();
  model.spawnIn = model.treatSpawnIn = 10000;
  return model;
}

void main() {
  for (final entry in {
    TreatKind.candy: SoundEffect.candy,
    TreatKind.chocolate: SoundEffect.chocolate,
    TreatKind.golden: SoundEffect.golden,
  }.entries) {
    test('${entry.key} sounds once only on genuine collection', () {
      final sounds = <SoundEffect>[];
      final model = runWithSounds(sounds);
      final treat = Treat(350, 25, entry.key);
      model.treats.add(treat);
      model.collect(treat);
      expect(sounds, isEmpty);
      treat.x = 100;
      model.update(1 / 120);
      model.collect(treat);
      model.update(.1);
      expect(sounds, [entry.value]);
      expect(model.treatsCollected, 1);
      expect(model.bonusScore, treat.points);
      model.start();
      model.treats.add(Treat(-39, 100, entry.key));
      model.update(.1);
      expect(sounds, [entry.value]); // Off-screen removal is silent.
    });
  }
  test(
    'Boing only for accepted jumps, including rapid taps before a frame',
    () {
      final sounds = <SoundEffect>[];
      final model = RunnerModel()..onSound = sounds.add;
      model.jump();
      expect(sounds, isEmpty);
      model.start();
      model.jump();
      model.jump();
      model.update(.1);
      model.jump();
      expect(sounds, [SoundEffect.jump]);
      for (var i = 0; i < 100; i++) {
        model.update(1 / 120);
      }
      model.jump();
      expect(sounds, [SoundEffect.jump, SoundEffect.jump]);
    },
  );
  test('Shield poof once; later unprotected collision gives one goodbye', () {
    final sounds = <SoundEffect>[];
    final model = runWithSounds(sounds);
    final shield = Treat(100, 25, TreatKind.shield);
    model.treats.add(shield);
    model.collect(shield);
    expect(sounds, isEmpty);
    model.obstacles.add(Obstacle(100, true));
    model.update(.05);
    model.update(.05);
    expect(sounds, [SoundEffect.shield]);
    model.obstacles.add(Obstacle(100, false));
    model.update(.1);
    model.update(5);
    expect(model.phase, RunPhase.gameOver);
    expect(sounds, [SoundEffect.shield, SoundEffect.death]);
    model.jump();
    expect(sounds.length, 2);
  });
  test('Jingle once per displayed 100-mile milestone, never from score', () {
    final sounds = <SoundEffect>[];
    final model = runWithSounds(sounds);
    model.distance = 99 * RunnerModel.worldUnitsPerMile;
    model.bonusScore = 10000;
    model.update(0);
    expect(sounds, isEmpty);
    model.distance = 100 * RunnerModel.worldUnitsPerMile;
    model.update(0);
    model.update(0);
    expect(sounds, [SoundEffect.milestone]);
    model.distance = 305 * RunnerModel.worldUnitsPerMile;
    for (var i = 0; i < 45; i++) {
      model.update(.1);
    }
    expect(sounds, List.filled(3, SoundEffect.milestone));
    model.start();
    model.distance = 100 * RunnerModel.worldUnitsPerMile;
    model.update(0);
    expect(sounds.length, 4);
  });
}

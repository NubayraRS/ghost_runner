import 'dart:math';
import 'dart:ui';

import 'sound_effect.dart';

enum RunPhase { menu, running, gameOver }

enum TreatKind { chocolate, candy, golden, shield }

class Treat {
  Treat(this.x, this.height, this.kind, {this.color = 0});
  double x;
  final double height;
  final TreatKind kind;
  final int color;
  int get points => switch (kind) {
    TreatKind.chocolate => 10,
    TreatKind.candy => 5,
    TreatKind.golden => 25,
    TreatKind.shield => 0,
  };
  bool get isTreat => kind != TreatKind.shield;
  Rect bounds(double ground) => Rect.fromLTWH(x, ground - height - 12, 30, 24);
}

class TreatPop {
  TreatPop(this.x, this.height);
  double x;
  final double height;
  double age = 0;
}

class Obstacle {
  Obstacle(this.x, this.isPumpkin);
  double x;
  final bool isPumpkin;
  bool shieldAbsorbed = false;
  double get width => isPumpkin ? 42 : 34;
  double get height => isPumpkin ? 36 : 49;
  Rect bounds(double ground) =>
      Rect.fromLTWH(x + 5, ground - height + 5, width - 10, height - 5);
}

/// Physics use a 400-unit wide world, independent of phone pixel density.
class RunnerModel {
  RunnerModel({Random? random}) : random = random ?? Random();
  final Random random;
  void Function(SoundEffect)? onSound;
  RunPhase phase = RunPhase.menu;
  final List<Obstacle> obstacles = [];
  final List<Treat> treats = [];
  final List<TreatPop> pops = [];
  int treatsCollected = 0, bonusScore = 0;
  bool shieldActive = false;
  double shieldBurstRemaining = 0;
  static const milestoneDuration = 1.8;
  int lastMilestone = 0, displayedMilestone = 0;
  double milestoneRemaining = 0;
  int get activeMilestone => milestoneRemaining > 0 ? displayedMilestone : 0;
  double treatSpawnIn = .65, celebrationRemaining = 0;
  double jumpHeight = 0, velocity = 0, elapsed = 0, distance = 0, spawnIn = 1.6;
  // distance is world travel for movement/parallax, not displayed miles.
  // Match the original HUD's starting pace (180 units/s -> 10 miles/s),
  // while allowing mileage to follow actual travel as running speed increases.
  static const worldUnitsPerMile = 18.0;
  double get miles => distance / worldUnitsPerMile;
  int get score => (elapsed * 10).floor() + bonusScore;
  double get speed => min(270, 180 + elapsed * 1.5);
  bool get grounded => jumpHeight == 0;
  void start() => _reset(RunPhase.running);

  void returnHome() => _reset(RunPhase.menu);

  void _reset(RunPhase nextPhase) {
    phase = nextPhase;
    obstacles.clear();
    treats.clear();
    pops.clear();
    treatsCollected = bonusScore = 0;
    shieldActive = false;
    shieldBurstRemaining = 0;
    lastMilestone = displayedMilestone = 0;
    milestoneRemaining = 0;
    treatSpawnIn = .65;
    celebrationRemaining = 0;
    jumpHeight = velocity = elapsed = distance = 0;
    spawnIn = 1.6;
  }

  void jump() {
    if (phase == RunPhase.running && grounded && velocity == 0) {
      velocity = 600;
      onSound?.call(SoundEffect.jump);
    }
  }

  Rect ghostBounds(double ground) =>
      Rect.fromLTWH(83, ground - 48 - jumpHeight, 31, 40);

  void collect(Treat treat) {
    // Flame callbacks may outlive a hitbox's model entry during removal/restart.
    // Validate current world contact before the single authoritative removal.
    if (phase != RunPhase.running ||
        !ghostBounds(0).overlaps(treat.bounds(0)) ||
        !treats.remove(treat)) {
      return;
    }
    if (treat.isTreat) {
      bonusScore += treat.points;
      treatsCollected++;
      onSound?.call(switch (treat.kind) {
        TreatKind.candy => SoundEffect.candy,
        TreatKind.chocolate => SoundEffect.chocolate,
        TreatKind.golden => SoundEffect.golden,
        TreatKind.shield => throw StateError('Shield is not a treat'),
      });
      if (treatsCollected == 5) celebrationRemaining = 2;
    } else {
      shieldActive = true;
    }
    pops.add(TreatPop(treat.x + 15, treat.height));
  }

  // Compact queue: never drop skipped thresholds or restart a celebration.
  // Distance can cross several milestones while a previous banner is visible.
  void _updateMilestones(double dt) {
    milestoneRemaining = max(0, milestoneRemaining - dt);
    lastMilestone = max(lastMilestone, (miles / 100).floor() * 100);
    if (milestoneRemaining == 0 && displayedMilestone < lastMilestone) {
      displayedMilestone += 100;
      milestoneRemaining = milestoneDuration;
      onSound?.call(SoundEffect.milestone);
    }
  }

  // Reserve horizontal room for a full jump, including at maximum speed.
  bool safeTreatPosition(double x) =>
      obstacles.every((o) => _hasTreatClearance(x, o.x, o.width));

  bool _hasTreatClearance(double treatX, double obstacleX, double width) =>
      treatX + 30 < obstacleX - 100 || treatX > obstacleX + width + 100;
  void update(double dt) {
    if (phase != RunPhase.running) return;
    _updateMilestones(0);
    // Substeps prevent tunnelling; cap long frames after interruptions.
    var remaining = dt.clamp(0.0, 0.1);
    while (remaining > 0 && phase == RunPhase.running) {
      final step = min(remaining, 1 / 120);
      remaining -= step;
      elapsed += step;
      celebrationRemaining = max(0, celebrationRemaining - step);
      shieldBurstRemaining = max(0, shieldBurstRemaining - step);
      for (final pop in pops) {
        pop.age += step;
        pop.x -= speed * step * .3;
      }
      pops.removeWhere((p) => p.age >= .5);
      distance += speed * step;
      _updateMilestones(step);
      if (jumpHeight > 0 || velocity > 0) {
        velocity -= 1500 * step;
        jumpHeight = max(0, jumpHeight + velocity * step);
        if (grounded) velocity = 0;
      }
      spawnIn -= step;
      // Existing treats own their space until collected or off-screen. Retry a
      // blocked obstacle spawn once there is room for either obstacle type.
      if (spawnIn <= 0 &&
          treats.every((t) => _hasTreatClearance(t.x, 430, 42))) {
        obstacles.add(Obstacle(430, random.nextBool()));
        spawnIn = 1.45 + random.nextDouble() * .65;
      }
      treatSpawnIn -= step;
      if (treatSpawnIn <= 0) {
        if (safeTreatPosition(430)) {
          final rarity = random.nextInt(100);
          final kind = rarity < 3
              ? TreatKind.shield
              : rarity < 9
              ? TreatKind.golden
              : random.nextBool()
              ? TreatKind.chocolate
              : TreatKind.candy;
          treats.add(
            Treat(
              430,
              random.nextBool() ? 25 : 100,
              kind,
              color: random.nextInt(3),
            ),
          );
        }
        treatSpawnIn = .65 + random.nextDouble() * .25;
      }
      for (final obstacle in obstacles) {
        obstacle.x -= speed * step;
        if (!obstacle.shieldAbsorbed &&
            ghostBounds(0).overlaps(obstacle.bounds(0))) {
          if (shieldActive) {
            shieldActive = false;
            obstacle.shieldAbsorbed = true;
            shieldBurstRemaining = .5;
            onSound?.call(SoundEffect.shield);
          } else {
            shieldActive = false;
            phase = RunPhase.gameOver;
            onSound?.call(SoundEffect.death);
            break;
          }
        }
      }
      obstacles.removeWhere((o) => o.x < -60);
      if (phase == RunPhase.running) {
        // Iterate backwards: collect removes only the current entry. Avoid a
        // temporary list on every physics substep.
        for (var i = treats.length - 1; i >= 0; i--) {
          final treat = treats[i];
          treat.x -= speed * step;
          if (ghostBounds(0).overlaps(treat.bounds(0))) collect(treat);
        }
      }
      treats.removeWhere((t) => t.x < -40);
    }
  }
}

import 'dart:ui';

import 'package:flame/components.dart';

import 'package:flame/events.dart';
import 'package:flame/collisions.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'halloween_art.dart';
import 'runner_model.dart';
import 'sky_background.dart';
import 'game_audio.dart';
import 'wardrobe_store.dart';

class GhostRunnerGame extends FlameGame
    with TapCallbacks, HasCollisionDetection {
  GhostRunnerGame({GameAudio? audio, WardrobeStore? wardrobe})
    : audio = audio ?? GameAudio.silent(),
      wardrobe = wardrobe ?? WardrobeStore.memory() {
    model.onSound = this.audio.play;
  }
  final GameAudio audio;
  final WardrobeStore wardrobe;
  final model = RunnerModel();
  final sky = SkyBackground();
  final phase = ValueNotifier(RunPhase.menu);
  final score = ValueNotifier(0);
  final miles = ValueNotifier(0);
  final treatsCollected = ValueNotifier(0);
  final celebrating = ValueNotifier(false);
  final milestone = ValueNotifier(0);
  final shieldActive = ValueNotifier(false);
  final Map<Treat, _TreatHitbox> _treatHitboxes = {};
  final _ghostHitbox = PositionComponent(children: [RectangleHitbox()]);

  @override
  Future<void> onLoad() async {
    await add(_ghostHitbox);
  }

  double animationTime = 0;
  void start() {
    audio.startRun();
    model.start();
    sky.reset();
    _resetHud(RunPhase.running);
  }

  void returnHome() {
    audio.suspend();
    model.returnHome();
    sky.reset();
    for (final hitbox in _treatHitboxes.values) {
      hitbox.removeFromParent();
    }
    _treatHitboxes.clear();
    _resetHud(RunPhase.menu);
  }

  void _resetHud(RunPhase nextPhase) {
    score.value = 0;
    miles.value = 0;
    treatsCollected.value = 0;
    celebrating.value = false;
    milestone.value = 0;
    shieldActive.value = false;
    phase.value = nextPhase;
  }

  @override
  void onTapDown(TapDownEvent event) {
    audio.unlockFromGesture();
    model.jump();
  }

  @override
  void update(double dt) {
    animationTime += dt.clamp(0, .1);
    model.update(dt);
    sky.update(model.miles);
    if (size.x > 0) {
      final scale = size.x / 400;
      final ground = size.y / scale * .79;
      final bounds = model.ghostBounds(ground);
      _ghostHitbox.position = Vector2(bounds.left, bounds.top) * scale;
      _ghostHitbox.size = Vector2(bounds.width, bounds.height) * scale;
      for (final treat in _treatHitboxes.keys.toList()) {
        if (!model.treats.contains(treat)) {
          _treatHitboxes.remove(treat)!.removeFromParent();
        }
      }
      for (final treat in model.treats) {
        final hitbox = _treatHitboxes.putIfAbsent(treat, () {
          final component = _TreatHitbox(this, treat);
          add(component);
          return component;
        });
        final rect = treat.bounds(ground);
        hitbox.position = Vector2(rect.left, rect.top) * scale;
        hitbox.size = Vector2(rect.width, rect.height) * scale;
      }
    }
    // Flame checks collisions in super.update: synchronize model, visuals and
    // hitboxes first so it sees this frame's positions (also after resizing).
    super.update(dt);
    score.value = model.score;
    miles.value = model.miles.floor();
    treatsCollected.value = model.treatsCollected;
    celebrating.value = model.celebrationRemaining > 0;
    milestone.value = model.activeMilestone;
    shieldActive.value = model.shieldActive;
    phase.value = model.phase;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    canvas.save();
    final scale = size.x / 400;
    canvas.scale(scale);
    final worldSize = Size(400, size.y / scale);
    final scroll = model.phase == RunPhase.menu
        ? animationTime * 24
        : model.distance;
    HalloweenArt.scene(
      canvas,
      worldSize,
      scroll,
      animationTime,
      skyPaint: sky.paintFor(worldSize),
    );
    final ground = worldSize.height * .79;
    if (model.phase != RunPhase.menu) {
      if (model.activeMilestone != 0) {
        HalloweenArt.treatPop(
          canvas,
          const Offset(200, 145),
          (RunnerModel.milestoneDuration - model.milestoneRemaining) /
              RunnerModel.milestoneDuration *
              .5,
        );
      }
      for (final treat in model.treats) {
        if (treat.kind == TreatKind.shield) {
          HalloweenArt.shieldPickup(
            canvas,
            treat.x,
            ground - treat.height,
            animationTime,
          );
        } else {
          HalloweenArt.treat(
            canvas,
            treat.x,
            ground - treat.height,
            treat.kind == TreatKind.chocolate,
            treat.color,
            golden: treat.kind == TreatKind.golden,
            time: animationTime,
          );
        }
      }
      for (final pop in model.pops) {
        HalloweenArt.treatPop(
          canvas,
          Offset(pop.x, ground - pop.height),
          pop.age,
        );
      }
      for (final obstacle in model.obstacles) {
        if (obstacle.isPumpkin) {
          HalloweenArt.pumpkin(canvas, obstacle.x, ground - 38, 1);
        } else {
          HalloweenArt.gravestone(canvas, obstacle.x, ground - 49);
        }
      }
      canvas.drawOval(
        Rect.fromLTWH(78, ground - 5, 45, 9),
        Paint()..color = const Color(0x55302247),
      );
      HalloweenArt.ghost(
        canvas,
        Offset(72, ground - 58 - model.jumpHeight),
        58,
        animationTime,
        costume: wardrobe.value,
      );
      if (model.shieldActive || model.shieldBurstRemaining > 0) {
        HalloweenArt.shieldBubble(
          canvas,
          Offset(101, ground - 30 - model.jumpHeight),
          animationTime,
          burst: model.shieldBurstRemaining > 0
              ? 1 - model.shieldBurstRemaining / .5
              : null,
        );
      }
    }
    canvas.restore();
  }
}

class _TreatHitbox extends PositionComponent with CollisionCallbacks {
  _TreatHitbox(this.game, this.treat)
    : super(children: [RectangleHitbox(collisionType: CollisionType.passive)]);
  final GhostRunnerGame game;
  final Treat treat;

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (identical(other, game._ghostHitbox)) game.model.collect(treat);
  }
}

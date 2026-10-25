import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/main.dart';
import 'package:ghost_runner/game/ghost_runner_game.dart';
import 'package:ghost_runner/game/runner_model.dart';
import 'package:ghost_runner/game/best_score_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Best score, milestone, shield and pause/resume work together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({BestScoreStore.storageKey: 20});
    final best = await BestScoreStore.load();
    await tester.pumpWidget(GhostRunnerApp(bestScore: best));
    await tester.pump();
    final game = tester
        .widget<GameWidget<GhostRunnerGame>>(
          find.byType(GameWidget<GhostRunnerGame>),
        )
        .game!;
    await tester.runAsync(() => game.loaded);
    await tester.pump();
    expect(find.text('BEST SCORE  20'), findsOneWidget);
    await tester.ensureVisible(find.text('Play'));
    await tester.tap(find.text('Play'));
    await tester.pump();
    game.model.spawnIn = game.model.treatSpawnIn = 10000;
    game.model.distance = 100 * RunnerModel.worldUnitsPerMile;
    game.model.treats.add(Treat(100, 25, TreatKind.shield));
    game.update(1 / 120);
    await tester.pump();
    expect(find.text('100 MILES! SPOOKY!'), findsOneWidget);
    expect(find.text('SHIELD ACTIVE'), findsOneWidget);
    final distance = game.model.distance;
    final bannerTime = game.model.milestoneRemaining;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    expect(game.model.distance, distance);
    expect(game.model.milestoneRemaining, bannerTime);
    expect(game.model.shieldActive, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    // The celebration must not intercept jump input on a small portrait screen.
    await tester.tapAt(const Offset(160, 350));
    await tester.pump(const Duration(milliseconds: 80));
    expect(game.model.jumpHeight, greaterThan(0));
    game.model.jumpHeight = game.model.velocity = 0;
    final golden = Treat(100, 25, TreatKind.golden);
    game.model.treats.add(golden);
    game.model.collect(golden);
    game.model.obstacles.add(Obstacle(100, true));
    game.update(1 / 120);
    await tester.pump();
    expect(game.model.phase, RunPhase.running);
    expect(find.text('SHIELD ACTIVE'), findsNothing);
    game.model.obstacles.add(Obstacle(100, false));
    game.update(1 / 120);
    await tester.pump();
    final score = game.model.score;
    expect(find.text('Game Over'), findsOneWidget);
    expect(find.text('BEST SCORE  $score'), findsOneWidget);
    expect(best.value, score);
    await best.record(score); // Wait for the already queued write.
    expect((await BestScoreStore.load()).value, score);
    await tester.ensureVisible(find.text('Restart'));
    await tester.tap(find.text('Restart'));
    await tester.pump();
    expect(game.model.shieldActive, isFalse);
    expect(game.model.lastMilestone, 0);
    expect(best.value, score);
    await tester.pumpWidget(const SizedBox.shrink());
    best.dispose();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Treat hitboxes stay aligned and stale callbacks cannot collect',
    (tester) async {
      final game = GhostRunnerGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      game.pauseEngine();
      game.start();
      game.model.spawnIn = 0;
      game.model.treatSpawnIn = 100;
      final treat = Treat(350, 100, TreatKind.candy);
      game.model.treats.add(treat);
      game.update(.5);
      game.update(0); // Mount queued hitboxes.
      final component = game.children.whereType<PositionComponent>().firstWhere(
        (c) => c is CollisionCallbacks,
      );
      final ghost = game.children.whereType<PositionComponent>().firstWhere(
        (c) => c is! CollisionCallbacks,
      );
      for (final width in [400.0, 800.0]) {
        game.onGameResize(Vector2(width, 800));
        game.update(0);
        final scale = width / 400;
        final bounds = treat.bounds(800 / scale * .79);
        expect(component.position.x, closeTo(bounds.left * scale, .001));
        expect(component.position.y, closeTo(bounds.top * scale, .001));
        expect(component.size.x, 30 * scale);
        expect(component.children.whereType<RectangleHitbox>(), hasLength(1));
      }
      (component as CollisionCallbacks).onCollisionStart({}, ghost);
      expect(game.model.treats, contains(same(treat)));
      expect(game.model.treatsCollected, 0);
      // Move into genuine contact and let the model and Flame both process it.
      treat.x = 100;
      game.model.jumpHeight = 80;
      game.update(1 / 120);
      (component as CollisionCallbacks).onCollisionStart({}, ghost);
      game.update(0);
      expect(game.model.treatsCollected, 1);
      expect(game.model.bonusScore, 5);
      expect(game.model.treats, isEmpty);
      expect(game.children, isNot(contains(component)));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Play, tap to jump, collision, score and restart work', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GhostRunnerApp());
    await tester.pump();
    final game = tester
        .widget<GameWidget<GhostRunnerGame>>(
          find.byType(GameWidget<GhostRunnerGame>),
        )
        .game!;
    await tester.runAsync(() => game.loaded);
    await tester.pump();
    expect(find.text('Play'), findsOneWidget);
    await tester.tap(find.text('Play'));
    await tester.pump();
    expect(game.model.phase, RunPhase.running);
    expect(find.text('TAP TO JUMP'), findsOneWidget);
    expect(find.text('Treats: 0'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      game.model.treats.add(Treat(100, 25, TreatKind.chocolate));
      game.update(1 / 120);
    }
    await tester.pump();
    expect(find.text('Treats: 5'), findsOneWidget);
    expect(game.model.bonusScore, 50);
    expect(game.celebrating.value, isTrue);
    expect(find.text('Trick or Treat!'), findsOneWidget);
    await tester.tapAt(const Offset(200, 400));
    await tester.pump(const Duration(milliseconds: 80));
    expect(game.model.jumpHeight, greaterThan(0));
    game.model.jumpHeight = 0;
    game.model.velocity = 0;
    game.model.obstacles.add(Obstacle(100, true));
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump();
    expect(find.text('Game Over'), findsOneWidget);
    expect(find.text('FINAL SCORE'), findsOneWidget);
    expect(find.text('Total treats: 5'), findsOneWidget);
    await tester.tap(find.text('Restart'));
    await tester.pump();
    expect(game.model.phase, RunPhase.running);
    expect(game.model.score, 0);
    expect(find.text('Treats: 0'), findsOneWidget);
    expect(game.model.obstacles, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(320, 568),
    const Size(412, 915),
    const Size(800, 1280),
  ]) {
    testWidgets('Menu fits portrait $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const GhostRunnerApp());
      await tester.pump();
      await tester.ensureVisible(find.text('Play'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

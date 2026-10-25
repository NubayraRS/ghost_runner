import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/ghost_costume.dart';
import 'package:ghost_runner/game/ghost_runner_game.dart';
import 'package:ghost_runner/game/runner_model.dart';
import 'package:ghost_runner/game/wardrobe_store.dart';
import 'package:ghost_runner/main.dart';
import 'package:ghost_runner/ui/ghost_portrait.dart';
import 'package:ghost_runner/ui/wardrobe_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GhostRunnerGame> loadGame(
  WidgetTester tester,
  WardrobeStore wardrobe,
) async {
  await tester.pumpWidget(GhostRunnerApp(wardrobe: wardrobe));
  await tester.pump();
  final game = tester
      .widget<GameWidget<GhostRunnerGame>>(
        find.byType(GameWidget<GhostRunnerGame>),
      )
      .game!;
  await tester.runAsync(() => game.loaded);
  await tester.pump();
  return game;
}

Future<void> openWardrobe(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Wardrobe'));
  await tester.tap(find.text('Wardrobe'));
  await tester.pump();
  for (var i = 0; i < 20; i++) {
    final element = find.byType(WardrobeScreen).evaluate().firstOrNull;
    if (element != null && ModalRoute.of(element)!.animation!.isCompleted) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump();
  expect(find.byType(WardrobeScreen), findsOneWidget);
}

Future<void> back(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Back'));
  await tester.pump();
  for (
    var i = 0;
    i < 20 && find.byType(WardrobeScreen).evaluate().isNotEmpty;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump();
  expect(find.byType(WardrobeScreen), findsNothing);
}

void main() {
  for (final size in [
    const Size(320, 568),
    const Size(412, 915),
    const Size(1100, 800),
  ]) {
    testWidgets('Wardrobe previews, free selections and Back fit $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final wardrobe = WardrobeStore.memory();
      final game = await loadGame(tester, wardrobe);
      expect(
        tester.widget<GhostPortrait>(find.byType(GhostPortrait)).costume,
        GhostCostume.original,
      );
      await openWardrobe(tester);
      expect(find.text('Ghost Wardrobe'), findsOneWidget);
      expect(find.text('FREE'), findsNWidgets(3));
      expect(find.text('Selected'), findsOneWidget);
      expect(
        tester
            .widgetList<GhostPortrait>(
              find.descendant(
                of: find.byType(WardrobeScreen),
                matching: find.byType(GhostPortrait),
              ),
            )
            .map((p) => p.costume),
        GhostCostume.values,
      );
      final animationTime = game.animationTime;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));
      expect(game.animationTime, animationTime); // Menu stays paused behind it.
      for (final costume in GhostCostume.values) {
        final card = find.byKey(ValueKey('costume-${costume.id}'));
        await tester.ensureVisible(card);
        await tester.tap(card);
        await tester.pump();
        expect(wardrobe.value, costume);
        expect(
          find.descendant(of: card, matching: find.text('Selected')),
          findsOneWidget,
        );
        expect(find.text('Selected'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await back(tester);
      expect(
        tester.widget<GhostPortrait>(find.byType(GhostPortrait)).costume,
        GhostCostume.skeleton,
      );
      expect(game.wardrobe.value, GhostCostume.skeleton);
      await tester.pumpWidget(const SizedBox.shrink());
      wardrobe.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Selected costume reaches Game Over, Restart and a fresh app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final wardrobe = await WardrobeStore.load();
    final game = await loadGame(tester, wardrobe);
    await openWardrobe(tester);
    final card = find.byKey(const ValueKey('costume-vampire'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pump();
    await back(tester);
    expect(
      tester.widget<GhostPortrait>(find.byType(GhostPortrait)).costume,
      GhostCostume.vampire,
    );
    await tester.ensureVisible(find.text('Play'));
    await tester.tap(find.text('Play'));
    await tester.pump();
    expect(game.wardrobe.value, GhostCostume.vampire);
    game.model.obstacles.add(Obstacle(100, true));
    game.update(.01);
    await tester.pump();
    expect(find.text('Game Over'), findsOneWidget);
    expect(
      tester.widget<GhostPortrait>(find.byType(GhostPortrait)).costume,
      GhostCostume.vampire,
    );
    await tester.ensureVisible(find.text('Restart'));
    await tester.tap(find.text('Restart'));
    await tester.pump();
    expect(game.wardrobe.value, GhostCostume.vampire);
    expect(game.model.phase, RunPhase.running);
    await wardrobe.select(GhostCostume.vampire); // Wait for the pending write.
    await tester.pumpWidget(const SizedBox.shrink());
    wardrobe.dispose();
    final restored = await WardrobeStore.load();
    final freshGame = await loadGame(tester, restored);
    expect(restored.value, GhostCostume.vampire);
    expect(freshGame.wardrobe.value, GhostCostume.vampire);
    expect(
      tester.widget<GhostPortrait>(find.byType(GhostPortrait)).costume,
      GhostCostume.vampire,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    restored.dispose();
    expect(tester.takeException(), isNull);
  });
}

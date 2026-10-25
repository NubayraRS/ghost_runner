import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/game_audio.dart';
import 'package:ghost_runner/game/ghost_runner_game.dart';
import 'package:ghost_runner/game/sound_effect.dart';
import 'package:ghost_runner/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sound_backend.dart';

void main() {
  testWidgets(
    'Menu and pause toggles persist; pausing blocks sound and input',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final backend = FakeSoundBackend();
      final audio = await GameAudio.load(backend: backend);
      await tester.pumpWidget(GhostRunnerApp(audio: audio));
      await tester.pump();
      final game = tester
          .widget<GameWidget<GhostRunnerGame>>(
            find.byType(GameWidget<GhostRunnerGame>),
          )
          .game!;
      await tester.runAsync(() => game.loaded);
      await tester.pump();
      await tester.ensureVisible(find.text('Sound ON'));
      await tester.tap(find.text('Sound ON'));
      await tester.pump();
      expect(find.text('Sound OFF'), findsOneWidget);
      expect(audio.value, isFalse);
      await tester.ensureVisible(find.text('Play'));
      await tester.tap(find.text('Play'));
      await tester.pump();
      game.model.spawnIn = game.model.treatSpawnIn = 10000;
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('Sound OFF'), findsOneWidget);
      final distance = game.model.distance;
      await tester.pump(const Duration(seconds: 1));
      expect(game.model.distance, distance);
      await tester.tap(find.text('Sound OFF'));
      await tester.pump();
      await audio.settled;
      expect(find.text('Sound ON'), findsOneWidget);
      expect(backend.played, isEmpty); // Unlocking is inaudible.
      expect(game.model.velocity, 0); // Toggling cannot jump the ghost.
      // Returning from the OS must not dismiss a manually requested pause.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Paused'), findsOneWidget);
      expect(game.model.distance, distance);
      await tester.tap(find.text('Resume'));
      await tester.pump();
      await audio.settled;
      expect(find.text('Paused'), findsNothing);
      await tester.tapAt(const Offset(160, 380));
      await tester.pump(const Duration(milliseconds: 80));
      await audio.settled;
      expect(backend.played, [SoundEffect.jump]);
      expect(game.model.jumpHeight, greaterThan(0));
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      final stops = backend.stops;
      await tester.tap(find.text('Sound ON'));
      await tester.pump();
      await audio.settled;
      expect(backend.stops, greaterThan(stops));
      final saved = await GameAudio.load(backend: FakeSoundBackend());
      expect(saved.value, isFalse);
      saved.dispose();
      await saved.settled;
      await tester.pumpWidget(const SizedBox.shrink());
      await audio.settled;
      expect(backend.disposed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}

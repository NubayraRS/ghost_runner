import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/game_audio.dart';
import 'package:ghost_runner/game/sound_effect.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_sound_backend.dart';

Future<void> activate(GameAudio audio) async {
  await audio.preload();
  audio.unlockFromGesture();
  await audio.settled;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Only plays after gesture, reuses preload and caps overlapping voices',
    () async {
      final backend = FakeSoundBackend();
      var now = 0;
      final audio = GameAudio(backend: backend, now: () => now);
      await audio.preload();
      audio.play(SoundEffect.candy);
      await audio.settled;
      expect(backend.played, isEmpty);
      await activate(audio);
      expect(backend.preloads, 1);
      audio.play(SoundEffect.candy);
      audio.play(SoundEffect.candy);
      audio.play(SoundEffect.chocolate);
      audio.play(SoundEffect.jump); // Two voices already occupied.
      await audio.settled;
      expect(backend.played, [SoundEffect.candy, SoundEffect.chocolate]);
      now = 1000;
      audio.play(
        SoundEffect.candy,
      ); // Genuine later collection may sound again.
      await audio.settled;
      expect(backend.played.length, 3);
      audio.dispose();
      await audio.settled;
      expect(backend.disposed, isTrue);
    },
  );
  test(
    'Mute cancels queued sounds; unmute never replays stale events',
    () async {
      final backend = FakeSoundBackend();
      final audio = GameAudio(backend: backend);
      await activate(audio);
      audio.play(SoundEffect.golden);
      await audio.setEnabled(false); // Cancel before the pending play executes.
      await audio.settled;
      audio.play(SoundEffect.jump);
      expect(backend.played, isEmpty);
      expect(backend.stops, greaterThan(0));
      await audio.setEnabled(true);
      await audio.settled;
      expect(backend.played, isEmpty);
      audio.play(SoundEffect.jump);
      await audio.settled;
      expect(backend.played, [SoundEffect.jump]);
      audio.dispose();
      await audio.settled;
    },
  );
  test(
    'Pause stops effects, death preempts them once, restart resets gating',
    () async {
      final backend = FakeSoundBackend();
      final audio = GameAudio(backend: backend);
      await activate(audio);
      audio.play(SoundEffect.milestone);
      await audio.settled;
      audio.suspend();
      audio.play(SoundEffect.chocolate);
      await audio.settled;
      expect(backend.played, [SoundEffect.milestone]);
      audio.resume();
      audio.play(SoundEffect.candy);
      await audio.settled;
      audio.play(SoundEffect.death);
      audio.play(SoundEffect.death);
      audio.play(SoundEffect.milestone);
      await audio.settled;
      expect(backend.played, [
        SoundEffect.milestone,
        SoundEffect.candy,
        SoundEffect.death,
      ]);
      expect(backend.stops, greaterThanOrEqualTo(2));
      audio.startRun();
      await audio.settled;
      audio.play(SoundEffect.jump);
      await audio.settled;
      expect(backend.played.last, SoundEffect.jump);
      audio.dispose();
      await audio.settled;
    },
  );
  test(
    'Load/unlock/play failures are nonfatal and browser gestures can retry',
    () async {
      final unavailable = FakeSoundBackend()..failPreload = true;
      final first = GameAudio(backend: unavailable);
      await activate(first);
      first.play(SoundEffect.candy);
      await first.settled;
      expect(unavailable.played, isEmpty);
      first.dispose();
      await first.settled;
      final backend = FakeSoundBackend()..unlockFailures = 1;
      final audio = GameAudio(backend: backend);
      await activate(audio);
      audio.play(SoundEffect.jump);
      await audio.settled;
      expect(backend.played, isEmpty);
      audio.unlockFromGesture();
      await audio.settled;
      backend.failPlay = true;
      audio.play(SoundEffect.candy);
      await audio.settled; // No uncaught async exception.
      expect(backend.unlocks, 2);
      audio.dispose();
      await audio.settled;
    },
  );
  test('Events during slow preload are dropped, not played late', () async {
    final backend = FakeSoundBackend()..loading = Completer<void>();
    final audio = GameAudio(backend: backend);
    audio.unlockFromGesture();
    audio.play(SoundEffect.milestone);
    await audio.setEnabled(false);
    backend.loading!.complete();
    await audio.settled;
    await audio.setEnabled(true);
    audio.unlockFromGesture();
    await audio.settled;
    expect(backend.played, isEmpty);
    audio.dispose();
    await audio.settled;
  });
  test(
    'Sound defaults ON and preference survives reload/rapid toggles',
    () async {
      final audio = await GameAudio.load(backend: FakeSoundBackend());
      expect(audio.value, isTrue);
      await audio.setEnabled(false);
      final next = await GameAudio.load(backend: FakeSoundBackend());
      expect(next.value, isFalse);
      final on = next.setEnabled(true);
      final off = next.setEnabled(false);
      await Future.wait([on, off]);
      final reloaded = await GameAudio.load(backend: FakeSoundBackend());
      expect(reloaded.value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(GameAudio.storageKey), isFalse);
      for (final instance in [audio, next, reloaded]) {
        instance.dispose();
        await instance.settled;
      }
    },
  );
  test(
    'All packaged effects are valid, short, audible, bounded PCM WAV assets',
    () async {
      var totalBytes = 0;
      for (final effect in SoundEffect.values) {
        final asset = await rootBundle.load('assets/audio/${effect.file}');
        final bytes = asset.buffer.asUint8List(
          asset.offsetInBytes,
          asset.lengthInBytes,
        );
        expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
        expect(String.fromCharCodes(bytes.skip(8).take(4)), 'WAVE');
        final data = ByteData.sublistView(bytes);
        expect(data.getUint16(20, Endian.little), 1); // PCM
        expect(data.getUint16(22, Endian.little), 1); // Mono
        expect(data.getUint32(24, Endian.little), 22050);
        expect(data.getUint16(34, Endian.little), 16);
        expect(data.getUint32(40, Endian.little), bytes.length - 44);
        final milliseconds = (bytes.length - 44) / 2 / 22050 * 1000;
        expect(milliseconds, closeTo(effect.milliseconds, 1));
        var peak = 0;
        for (var offset = 44; offset < bytes.length; offset += 2) {
          final value = data.getInt16(offset, Endian.little).abs();
          if (value > peak) peak = value;
        }
        expect(peak, inInclusiveRange(1000, 19000));
        expect(effect.volume, inExclusiveRange(0, .6));
        totalBytes += bytes.length;
      }
      expect(totalBytes, lessThan(180000));
      expect(File('assets/audio/LICENSE.txt').existsSync(), isTrue);
    },
  );
}

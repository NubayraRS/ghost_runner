import 'dart:async';

import 'package:ghost_runner/game/sound_backend.dart';
import 'package:ghost_runner/game/sound_effect.dart';

class FakeSoundBackend implements SoundBackend {
  final played = <SoundEffect>[];
  Completer<void>? loading;
  bool failPreload = false, failPlay = false, disposed = false;
  int unlockFailures = 0, unlocks = 0, stops = 0, preloads = 0;

  @override
  Future<void> preload() async {
    preloads++;
    if (failPreload) throw StateError('No audio device');
    await loading?.future;
  }

  @override
  Future<void> unlock() async {
    unlocks++;
    if (unlockFailures-- > 0) throw StateError('Gesture required');
  }

  @override
  Future<void> play(SoundEffect effect) async {
    if (failPlay) throw StateError('Playback unavailable');
    played.add(effect);
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async => disposed = true;
}

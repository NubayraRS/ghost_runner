import 'package:flame_audio/flame_audio.dart';

import 'sound_effect.dart';

abstract interface class SoundBackend {
  Future<void> preload();
  Future<void> unlock();
  Future<void> play(SoundEffect effect);
  Future<void> stop();
  Future<void> dispose();
}

/// One reusable, preloaded player per effect. No new players during gameplay.
class FlameSoundBackend implements SoundBackend {
  final Map<SoundEffect, AudioPlayer> _players = {};
  bool _disposed = false, _unlocked = false;

  @override
  Future<void> preload() async {
    for (final effect in SoundEffect.values) {
      if (_disposed) return;
      final player = AudioPlayer()..audioCache = FlameAudio.audioCache;
      _players[effect] = player;
      // Disable position polling; these are short one-shot effects.
      player.positionUpdater = null;
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0);
      await player.setSource(AssetSource(effect.file));
    }
  }

  @override
  Future<void> unlock() async {
    if (_unlocked || _disposed) return;
    // Called from Play, Resume, or a pointer gesture. Resume each preloaded
    // web AudioContext at zero volume, then stop it; no audible startup sound.
    await Future.wait(
      _players.values.map((player) async {
        await player.setVolume(0);
        await player.resume();
        await player.stop();
      }),
    );
    _unlocked = true;
  }

  @override
  Future<void> play(SoundEffect effect) async {
    if (_disposed) return;
    final player = _players[effect];
    if (player == null) return;
    await player.setVolume(effect.volume);
    await player.resume();
  }

  @override
  Future<void> stop() async {
    await Future.wait(_players.values.map((player) => player.stop()));
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await Future.wait(_players.values.map((player) => player.dispose()));
    _players.clear();
  }
}

/// Keeps model/widget tests and embedded games independent of platform plugins.
class SilentSoundBackend implements SoundBackend {
  @override
  Future<void> preload() async {}
  @override
  Future<void> unlock() async {}
  @override
  Future<void> play(SoundEffect effect) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

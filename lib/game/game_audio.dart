import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sound_backend.dart';
import 'sound_effect.dart';

/// Sound is optional: nothing here is awaited by the physics/render loop.
class GameAudio extends ValueNotifier<bool> {
  factory GameAudio({
    required SoundBackend backend,
    bool enabled = true,
    SharedPreferences? preferences,
    int Function()? now,
  }) => GameAudio._(backend, enabled, preferences, now);

  GameAudio._(this._backend, bool enabled, this._preferences, this._now)
    : super(enabled);

  factory GameAudio.silent() => GameAudio(backend: SilentSoundBackend());

  static const storageKey = 'ghost_runner.sound_enabled';
  static const maxVoices = 2;
  final SoundBackend _backend;
  final SharedPreferences? _preferences;
  final int Function()? _now;
  final _clock = Stopwatch()..start();
  final Map<SoundEffect, int> _activeUntil = {};
  Future<void>? _loading, _unlocking;
  Future<void> _commands = Future.value(), _saving = Future.value();
  bool _ready = false, _unlocked = false, _suspended = false;
  bool _ended = false, _disposed = false, _reportedError = false;
  int _generation = 0;

  static Future<GameAudio> load({SoundBackend? backend}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.get(storageKey);
      return GameAudio(
        backend: backend ?? FlameSoundBackend(),
        preferences: prefs,
        enabled: stored is bool ? stored : true,
      );
    } catch (_) {
      return GameAudio(backend: backend ?? FlameSoundBackend());
    }
  }

  Future<void> preload() => _loading ??= _preload();

  Future<void> _preload() async {
    try {
      await _backend.preload().timeout(const Duration(seconds: 8));
      _ready = !_disposed;
    } catch (error) {
      _report(error);
    }
  }

  /// Called directly by Play/Resume and the screen's pointer-down listener.
  /// If a browser rejects playback, the next user gesture can try again.
  void unlockFromGesture() {
    if (_disposed || !value || _unlocked || _unlocking != null) return;
    _unlocking = _unlock().whenComplete(() => _unlocking = null);
  }

  Future<void> _unlock() async {
    await preload();
    if (!_ready || _disposed || !value) return;
    try {
      await _backend.unlock().timeout(const Duration(seconds: 3));
      _unlocked = !_disposed;
    } catch (error) {
      _report(error);
    }
  }

  bool get _allowed =>
      !_disposed && value && _ready && _unlocked && !_suspended;

  void play(SoundEffect effect) {
    if (_disposed || _ended) return;
    final terminal = effect == SoundEffect.death;
    if (terminal) {
      _ended = true;
      _stopCurrent(); // Let the short goodbye play by itself.
    }
    if (!_allowed) return; // Never replay delayed/stale events after loading.
    final now = _now?.call() ?? _clock.elapsedMilliseconds;
    _activeUntil.removeWhere((_, end) => end <= now);
    if (_activeUntil.containsKey(effect)) return;
    if (_activeUntil.length >= maxVoices) {
      if (!effect.priority) return;
      _stopCurrent();
    }
    _activeUntil[effect] = now + effect.milliseconds;
    final generation = _generation;
    _enqueue(() async {
      if (_allowed && generation == _generation && (!_ended || terminal)) {
        await _backend.play(effect);
      }
    });
  }

  void startRun() {
    if (_disposed) return;
    _ended = _suspended = false;
    _stopCurrent();
    unlockFromGesture();
  }

  void suspend() {
    if (_disposed) return;
    _suspended = true;
    _stopCurrent();
  }

  void resume() {
    if (!_disposed) _suspended = false;
  }

  void _stopCurrent() {
    _generation++;
    _activeUntil.clear();
    if (_ready) _enqueue(_backend.stop);
  }

  Future<void> setEnabled(bool enabled) {
    if (_disposed || enabled == value) return _saving;
    value = enabled;
    if (!enabled) {
      _stopCurrent();
    } else {
      unlockFromGesture();
    }
    _saving = _saving
        .then((_) async {
          await _preferences?.setBool(storageKey, enabled);
        })
        .catchError((Object error) => _report(error));
    return _saving;
  }

  void _enqueue(Future<void> Function() action) {
    _commands = _commands
        .then((_) => action().timeout(const Duration(seconds: 3)))
        .catchError((Object error) => _report(error));
  }

  void _report(Object error) {
    if (_reportedError) return;
    _reportedError = true;
    debugPrint('Sound unavailable; Ghost Runner will keep playing: $error');
  }

  /// Also useful when tests or owners need to wait for pending audio work.
  Future<void> get settled async {
    await _loading;
    await _unlocking;
    await _commands;
    await _saving;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _activeUntil.clear();
    _enqueue(() async {
      await _loading;
      await _backend.dispose();
    });
    _clock.stop();
    super.dispose();
  }
}

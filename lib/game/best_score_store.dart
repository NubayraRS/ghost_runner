import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loaded before runApp; serializes record writes so older runs cannot win races.
class BestScoreStore extends ValueNotifier<int> {
  BestScoreStore.memory() : _preferences = null, _persisted = 0, super(0);
  BestScoreStore._(this._preferences, int score)
    : _persisted = score,
      super(score);

  static const storageKey = 'ghost_runner.best_score';
  final SharedPreferences? _preferences;
  int _persisted;
  Future<void> _pending = Future.value();

  static Future<BestScoreStore> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.get(storageKey);
      return BestScoreStore._(prefs, stored is int && stored >= 0 ? stored : 0);
    } catch (_) {
      // Disabled/private browser storage must not prevent playing.
      return BestScoreStore.memory();
    }
  }

  Future<void> record(int score) {
    if (score <= value) return _pending;
    value = score;
    _pending = _pending
        .then((_) async {
          final prefs = _preferences;
          if (prefs != null && score > _persisted) {
            if (await prefs.setInt(storageKey, score)) _persisted = score;
          }
        })
        .catchError((Object error) {
          // Keep the session record usable even if the platform rejects a write.
          debugPrint('Best score could not be saved: $error');
        });
    return _pending;
  }
}

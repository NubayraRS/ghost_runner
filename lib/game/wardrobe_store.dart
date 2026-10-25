import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ghost_costume.dart';

/// Visual preference only. Loaded before the app first renders, like best score.
class WardrobeStore extends ValueNotifier<GhostCostume> {
  WardrobeStore.memory({GhostCostume selected = GhostCostume.original})
    : _preferences = null,
      super(selected);
  WardrobeStore._(this._preferences, super.value);

  static const storageKey = 'ghost_runner.costume';
  final SharedPreferences? _preferences;
  Future<void> _pending = Future.value();

  static Future<WardrobeStore> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return WardrobeStore._(
        prefs,
        GhostCostume.fromStored(prefs.get(storageKey)),
      );
    } catch (_) {
      return WardrobeStore.memory();
    }
  }

  Future<void> select(GhostCostume costume) {
    if (value == costume) return _pending;
    value = costume;
    _pending = _pending
        .then((_) async {
          await _preferences?.setString(storageKey, costume.id);
        })
        .catchError((Object error) {
          debugPrint(
            'Costume could not be saved; keeping this session selection: $error',
          );
        });
    return _pending;
  }
}

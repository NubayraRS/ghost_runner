import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/ghost_costume.dart';
import 'package:ghost_runner/game/wardrobe_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Exactly three costumes; new players start with Original Ghost',
    () async {
      expect(GhostCostume.values.map((c) => c.label), [
        'Original Ghost',
        'Vampire Ghost',
        'Skeleton Ghost',
      ]);
      final store = await WardrobeStore.load();
      expect(store.value, GhostCostume.original);
      store.dispose();
    },
  );
  for (final costume in GhostCostume.values) {
    test(
      '${costume.label} survives a fresh preference/store instance',
      () async {
        final store = await WardrobeStore.load();
        await store.select(costume);
        final reloaded = await WardrobeStore.load();
        expect(reloaded.value, costume);
        store.dispose();
        reloaded.dispose();
      },
    );
  }
  for (final invalid in ['unknown', '', 'VAMPIRE', 42, true, <String>[]]) {
    test('Invalid costume $invalid falls back to Original Ghost', () async {
      SharedPreferences.setMockInitialValues({
        WardrobeStore.storageKey: invalid,
      });
      final store = await WardrobeStore.load();
      expect(store.value, GhostCostume.original);
      store.dispose();
    });
  }
  test(
    'Rapid choices save the last selection without changing other settings',
    () async {
      SharedPreferences.setMockInitialValues({
        'ghost_runner.best_score': 999,
        'ghost_runner.sound_enabled': false,
      });
      final store = await WardrobeStore.load();
      final writes = [
        store.select(GhostCostume.vampire),
        store.select(GhostCostume.original),
        store.select(GhostCostume.skeleton),
      ];
      expect(store.value, GhostCostume.skeleton);
      await Future.wait(writes);
      final reloaded = await WardrobeStore.load();
      expect(reloaded.value, GhostCostume.skeleton);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('ghost_runner.best_score'), 999);
      expect(prefs.getBool('ghost_runner.sound_enabled'), isFalse);
      store.dispose();
      reloaded.dispose();
    },
  );
}

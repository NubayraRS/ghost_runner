import 'package:flutter_test/flutter_test.dart';
import 'package:ghost_runner/game/best_score_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Best score loads zero, persists, and survives a new store instance',
    () async {
      final store = await BestScoreStore.load();
      expect(store.value, 0);
      await store.record(125);
      final reloaded = await BestScoreStore.load();
      expect(reloaded.value, 125);
      store.dispose();
      reloaded.dispose();
    },
  );
  test('Lower/equal records never overwrite the persisted best', () async {
    SharedPreferences.setMockInitialValues({BestScoreStore.storageKey: 250});
    final store = await BestScoreStore.load();
    expect(store.value, 250);
    var changes = 0;
    store.addListener(() => changes++);
    await store.record(50);
    await store.record(250);
    expect(changes, 0);
    expect(
      (await SharedPreferences.getInstance()).getInt(BestScoreStore.storageKey),
      250,
    );
    await store.record(300);
    expect(changes, 1);
    expect((await BestScoreStore.load()).value, 300);
    store.dispose();
  });
  test('Overlapping writes cannot regress the saved record', () async {
    final store = await BestScoreStore.load();
    final first = store.record(10);
    final second = store.record(500);
    final lower = store.record(100);
    expect(store.value, 500);
    await Future.wait([first, second, lower]);
    expect((await BestScoreStore.load()).value, 500);
    store.dispose();
  });
  test('Malformed/negative storage falls back safely to zero', () async {
    for (final invalid in ['not a score', -10]) {
      SharedPreferences.setMockInitialValues({
        BestScoreStore.storageKey: invalid,
      });
      final store = await BestScoreStore.load();
      expect(store.value, 0);
      await store.record(10);
      expect((await BestScoreStore.load()).value, 10);
      store.dispose();
    }
  });
}

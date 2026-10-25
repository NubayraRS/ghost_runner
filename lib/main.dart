import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/game_screen.dart';
import 'game/best_score_store.dart';
import 'game/game_audio.dart';
import 'game/wardrobe_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final bestScore = await BestScoreStore.load();
  final audio = await GameAudio.load();
  final wardrobe = await WardrobeStore.load();
  runApp(
    GhostRunnerApp(bestScore: bestScore, audio: audio, wardrobe: wardrobe),
  );
}

class GhostRunnerApp extends StatelessWidget {
  const GhostRunnerApp({super.key, this.bestScore, this.audio, this.wardrobe});
  final BestScoreStore? bestScore;
  final GameAudio? audio;
  final WardrobeStore? wardrobe;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ghost Runner: Halloween Dash',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF9575CD),
        brightness: Brightness.dark,
      ),
    ),
    home: GameScreen(bestScore: bestScore, audio: audio, wardrobe: wardrobe),
  );
}

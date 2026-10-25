import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/ghost_runner_game.dart';
import '../game/runner_model.dart';
import '../game/best_score_store.dart';
import '../game/game_audio.dart';
import '../game/ghost_costume.dart';
import '../game/wardrobe_store.dart';
import 'ghost_portrait.dart';
import 'wardrobe_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.bestScore, this.audio, this.wardrobe});
  final BestScoreStore? bestScore;
  final GameAudio? audio;
  final WardrobeStore? wardrobe;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final audio = widget.audio ?? GameAudio.silent();
  late final wardrobe = widget.wardrobe ?? WardrobeStore.memory();
  late final game = GhostRunnerGame(audio: audio, wardrobe: wardrobe);
  bool _userPaused = false, _appPaused = false, _wardrobeOpen = false;
  late final bestScore = widget.bestScore ?? BestScoreStore.memory();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    game.phase.addListener(_recordBest);
    unawaited(audio.preload());
  }

  void _recordBest() {
    if (game.phase.value == RunPhase.gameOver) {
      unawaited(bestScore.record(game.model.score));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appPaused = false;
      if (!_userPaused && !_wardrobeOpen) {
        game.resumeEngine();
        audio.resume();
      }
    } else {
      _appPaused = true;
      game.pauseEngine();
      audio.suspend();
      unawaited(bestScore.record(game.model.score));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    game.pauseEngine();
    audio.dispose();
    game.phase.removeListener(_recordBest);
    unawaited(bestScore.record(game.model.score));
    game.phase.dispose();
    game.score.dispose();
    game.miles.dispose();
    game.treatsCollected.dispose();
    game.celebrating.dispose();
    game.milestone.dispose();
    game.shieldActive.dispose();
    if (widget.bestScore == null) bestScore.dispose();
    if (widget.wardrobe == null) wardrobe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF25203F),
    body: Listener(
      onPointerDown: (_) => audio.unlockFromGesture(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          ValueListenableBuilder<RunPhase>(
            valueListenable: game.phase,
            builder: (context, phase, _) {
              if (phase == RunPhase.running) {
                return IgnorePointer(
                  child: SafeArea(
                    child: Column(
                      children: [
                        const SizedBox(height: 22),
                        const Text(
                          'MOONLIGHT MILES',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 3,
                            color: Color(0xFFDDD0ED),
                          ),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: game.miles,
                          builder: (_, miles, _) => Text(
                            '$miles'.padLeft(4, '0'),
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFFE8CA),
                            ),
                          ),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: game.score,
                          builder: (_, score, _) => Text(
                            'Score: $score',
                            style: const TextStyle(
                              color: Color(0xFFFFE8CA),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: game.treatsCollected,
                          builder: (_, count, _) => Text(
                            'Treats: $count',
                            style: const TextStyle(
                              color: Color(0xFFFFDBAC),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: game.shieldActive,
                          builder: (_, active, _) => SizedBox(
                            height: 24,
                            child: active
                                ? const Text(
                                    'SHIELD ACTIVE',
                                    style: TextStyle(
                                      color: Color(0xFFBAFFF5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        ValueListenableBuilder<int>(
                          valueListenable: game.milestone,
                          builder: (_, miles, _) => SizedBox(
                            height: 54,
                            child: miles == 0
                                ? null
                                : Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xE6402C51),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFFFDBAC),
                                        ),
                                      ),
                                      child: Text(
                                        '$miles MILES! SPOOKY!',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFFFE8CA),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: game.celebrating,
                          builder: (_, visible, _) => AnimatedOpacity(
                            opacity: visible ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Trick or Treat!',
                                style: TextStyle(
                                  color: Color(0xFFFFC48C),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 28),
                          child: Text(
                            'TAP TO JUMP',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 3,
                              color: Color(0xFFCCB8DB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ColoredBox(
                color: phase == RunPhase.gameOver
                    ? const Color(0x77302347)
                    : Colors.transparent,
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 24,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: phase == RunPhase.menu
                                  ? _menu()
                                  : _gameOver(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          ValueListenableBuilder<RunPhase>(
            valueListenable: game.phase,
            builder: (_, phase, _) => phase == RunPhase.running
                ? _pauseControls()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    ),
  );

  void _pauseRun() {
    setState(() => _userPaused = true);
    game.pauseEngine();
    audio.suspend();
    unawaited(bestScore.record(game.model.score));
  }

  void _resumeRun() {
    setState(() => _userPaused = false);
    if (!_appPaused) {
      audio.resume();
      audio.unlockFromGesture();
      game.resumeEngine();
    }
  }

  void _goHome() {
    // Capture the score before clearing the run, including when leaving Pause.
    unawaited(bestScore.record(game.model.score));
    setState(() => _userPaused = false);
    game.returnHome();
    // Keep the existing animated menu alive; the model is idle in menu phase.
    if (!_appPaused) game.resumeEngine();
  }

  Widget _homeButton() => OutlinedButton.icon(
    onPressed: _goHome,
    icon: const Icon(Icons.home_rounded),
    label: const Text('Home'),
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFFFFDBAC),
      backgroundColor: const Color(0xFF503D67),
      minimumSize: const Size(double.infinity, 48),
      side: const BorderSide(color: Color(0xFFB89BC9)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );

  Widget _pauseControls() => Stack(
    children: [
      if (!_userPaused)
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          right: 12,
          child: IconButton.filledTonal(
            tooltip: 'Pause',
            onPressed: _pauseRun,
            icon: const Icon(Icons.pause_rounded),
          ),
        ),
      if (_userPaused)
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xAA25203F),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: const Color(0xFF46365E),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFF977BAE)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'A LITTLE BOO BREAK',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            color: Color(0xFFFFC48C),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Paused',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFFF4E8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _soundToggle(),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _resumeRun,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Resume'),
                        ),
                        const SizedBox(height: 12),
                        _homeButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _soundToggle() => ValueListenableBuilder<bool>(
    valueListenable: audio,
    builder: (_, enabled, _) => TextButton.icon(
      onPressed: () => unawaited(audio.setEnabled(!enabled)),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFDBAC)),
      icon: Icon(enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded),
      label: Text(enabled ? 'Sound ON' : 'Sound OFF'),
    ),
  );
  Widget _menu() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        'A LITTLE BOO. A BIG ADVENTURE.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 2.1,
          color: Color(0xFFE2C9EE),
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Ghost\nRunner',
        textAlign: TextAlign.center,
        style: TextStyle(
          height: .96,
          fontSize: 62,
          fontWeight: FontWeight.w900,
          letterSpacing: -2,
          color: Color(0xFFFFF6EA),
          shadows: [
            Shadow(
              color: Color(0xFF49355F),
              offset: Offset(0, 5),
              blurRadius: 1,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'H A L L O W E E N  D A S H',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFBE82),
        ),
      ),
      _portrait(),
      const Text(
        'Small ghost. Endless possibilities.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFFF3E4FA), fontSize: 15),
      ),
      const SizedBox(height: 24),
      _bestScore(),
      const SizedBox(height: 12),
      _button('Play', Icons.play_arrow_rounded),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _openWardrobe,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFDBAC),
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: Color(0xFFB89BC9)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.checkroom_rounded),
        label: const Text('Wardrobe'),
      ),
      _soundToggle(),
      const SizedBox(height: 16),
      const Text(
        'Tap to jump • Dodge pumpkins & gravestones',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Color(0xFFDFCEE9)),
      ),
      const SizedBox(height: 18),
      const Text(
        '✦  A COZY HALLOWEEN ADVENTURE  ✦',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 1.5,
          color: Color(0xFFCEB9DE),
        ),
      ),
    ],
  );
  Widget _gameOver() => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: const Color(0xF246365E),
      borderRadius: BorderRadius.circular(32),
      border: Border.all(color: const Color(0xFF977BAE)),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 30, offset: Offset(0, 12)),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'BOO… A LITTLE BUMP!',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.6,
            color: Color(0xFFFFC48C),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Game Over',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFFF4E8),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(height: 100, child: _portrait()),
        const Text(
          'FINAL SCORE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: Color(0xFFD3BCE6),
          ),
        ),
        Text(
          '${game.model.score}',
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            color: Color(0xFFFFCC95),
          ),
        ),
        Text(
          'Total treats: ${game.model.treatsCollected}',
          style: const TextStyle(fontSize: 18, color: Color(0xFFFFDBAC)),
        ),
        const SizedBox(height: 12),
        _bestScore(),
        const SizedBox(height: 12),
        const Text(
          'Every little ghost gets another go.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFFE2D4EF)),
        ),
        const SizedBox(height: 24),
        _button('Restart', Icons.replay_rounded),
        const SizedBox(height: 12),
        _homeButton(),
      ],
    ),
  );
  Widget _portrait() => ValueListenableBuilder<GhostCostume>(
    valueListenable: wardrobe,
    builder: (_, costume, _) => GhostPortrait(costume: costume),
  );

  Future<void> _openWardrobe() async {
    if (_wardrobeOpen) return;
    _wardrobeOpen = true;
    game.pauseEngine();
    audio.suspend();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => WardrobeScreen(wardrobe: wardrobe)),
      );
    } finally {
      _wardrobeOpen = false;
      if (mounted && !_appPaused && !_userPaused) {
        game.resumeEngine();
        audio.resume();
      }
    }
  }

  Widget _bestScore() => ValueListenableBuilder<int>(
    valueListenable: bestScore,
    builder: (_, value, _) => Text(
      'BEST SCORE  $value',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFFFFDBAC),
      ),
    ),
  );

  Widget _button(String label, IconData icon) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: game.start,
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFBE83),
        foregroundColor: const Color(0xFF44304F),
        minimumSize: const Size(0, 62),
        elevation: 6,
        shadowColor: const Color(0x66302145),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
      ),
    ),
  );
}

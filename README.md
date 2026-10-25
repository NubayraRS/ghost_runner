# Ghost Runner: Halloween Dash

Phase 1 of a cute portrait Android endless runner. All illustrations are drawn
with Canvas paths, shapes and gradients; no external image assets are needed.

## Run

With Flutter installed and an Android device or emulator connected:

```sh
flutter pub get
flutter run
```

For Chrome (run from the existing project folder in PowerShell):

```powershell
Set-Location 'C:\Users\rashm\OneDrive\Desktop\Flutter Projects\ghost_runner'
flutter pub get
flutter run -d chrome --web-port 7357
```

Use the same port/browser profile on later launches to retain the web best score.
For persistence checks, open `http://localhost:7357` in your regular Chrome
window; Flutter's automatically launched debug browser may use a temporary profile.
The record is local to the browser or Android installation, with no account.

Tap **Play**, then tap anywhere in the game to jump. Clear pumpkins and
gravestones. Your score increases by 10 points per second survived. A collision
ends the run unless a shield absorbs it; **Restart** begins a fresh run.
Wrapped candy gives +5, chocolate +10, and rare golden candy +25. The magical
shield pickup gives no points or treats and protects against one obstacle only.
Best score is loaded before the menu appears and saved on Game Over or when the
app leaves the foreground.

The HUD displays actual miles: world travel divided by 18 (10 miles/second at
the initial running speed). Score is shown separately and includes treat bonuses.
Every 100 miles triggers a milestone; the purple/red/orange sky cycle changes
every 500 miles, blending only in the first 50 miles after each threshold.
Neither feature uses score or the decorative animation clock. Milestone banners
queue for 1.8 seconds each when thresholds arrive faster than they can be read.
Moving bats, twinkling stars and three drifting fog shapes are decorative only.

Open **Wardrobe** on the menu to choose **Original Ghost**, **Vampire Ghost**,
or **Skeleton Ghost**. All three are free and available immediately. Tap a card,
then use **Back** and **Play**. The same canvas renderer supplies the previews,
in-game ghost and Game Over portrait. Costumes change appearance only; jump,
hitboxes, scoring and difficulty are unchanged. Selection survives Restart and
is stored locally before the next app launch (no account or new dependency).
For Chrome persistence, reuse the regular browser profile and fixed port above.

Sound effects default to ON. Use **Sound ON/OFF** on the menu or press the
top-right **Pause** button to change it mid-run. The preference is saved locally.
Play/Resume/taps unlock browser audio; sounds do not autoplay on page load.
Effects are preloaded and reuse seven players with at most two audible effects
at once. Pause, mute and leaving the app stop effects; Game Over stops other
effects before its short ghost goodbye. No background music is played.

The seven WAV effects in `assets/audio/` are original synthesized sound designs
(CC0, see `assets/audio/LICENSE.txt`). Regenerate them with
`python tool/generate_sounds.py` (Python standard library only).

```sh
flutter analyze
flutter test
flutter build apk --debug
```

The debug APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`.

## Code map

- `lib/main.dart`: app theme and portrait orientation.
- `lib/ui/game_screen.dart`: responsive menu, animated ghost portrait, score HUD,
  game-over card and app lifecycle pause/resume handling.
- `lib/game/ghost_runner_game.dart`: Flame update/render loop and tap input.
- `lib/game/runner_model.dart`: testable physics, scoring, spawning and collision.
- `lib/game/halloween_art.dart`: original ghost, pumpkins, gravestones and layered
  moonlit scenery.
- `test/runner_model_test.dart`: jump, collision, obstacle spacing and reset tests.
- `test/widget_test.dart`: Play/jump/game-over/Restart interaction and portrait
  layout tests.

## Gameplay tuning

The world is 400 logical units wide and scales to the display. The ground is at
79% of the viewport height. Gravity is 1500 units/second squared and the jump
impulse is 600 units/second. Speed rises from 180 to a maximum of 270 units/second.
Obstacles spawn every 1.45–2.10 seconds, with a 1.6 second initial delay. The
slightly inset collision rectangles make near misses forgiving. Physics run in
steps no larger than 1/120 second, and long frames are capped to avoid sudden
teleports. Returning from the background resumes the same run.

The menu and game-over screen scroll when vertical space or accessibility text
size requires it. HUD controls respect Android safe areas.

No ads, purchases, online services, or store integration are included.
The Android release signing configuration is still the Flutter template's debug
configuration; this project is intended for local course demos at this stage.

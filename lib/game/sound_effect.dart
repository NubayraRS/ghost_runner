/// Immutable effect metadata shared by gameplay and the audio adapter.
enum SoundEffect {
  candy('candy_pop.wav', .50, 180),
  chocolate('chocolate_ding.wav', .42, 360),
  golden('golden_chime.wav', .38, 700),
  jump('ghost_boing.wav', .40, 300),
  death('ghost_boo.wav', .42, 720),
  shield('shield_poof.wav', .44, 400),
  milestone('milestone_jingle.wav', .38, 900);

  const SoundEffect(this.file, this.volume, this.milliseconds);
  final String file;
  final double volume;
  final int milliseconds;
  bool get priority =>
      this == death || this == shield || this == golden || this == milestone;
}

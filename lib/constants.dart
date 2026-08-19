part of 'main.dart';

enum AppTab { home, music, character, custom, quest, shop, settings }

enum Difficulty { easy, normal, hard, extreme }

enum Judge { perfect, great, good, miss }

const playHudTop = 18.0;
// Matches ContainFrame's design canvas exactly (1300x600, ~2.17:1) so the
// play screen fills the same widescreen phone/monitor shape as every other
// screen. It used to be its own 1448x1086 (~1.33:1) canvas, which is much
// closer to 4:3 — on a modern ~19.5:9 phone that got letterboxed into thick
// black bars on both sides.
const playStageWidth = ContainFrame.designWidth;
const playStageHeight = ContainFrame.designHeight;

// Real length of assets/music/distorted_rhythm.wav (93.48s), measured from
// the file itself. The chart and the in-game clock are both built around
// this so gameplay runs the full song instead of stopping early.
const distortedRhythmDurationMs = 93480;

String formatClock(int ms) {
  final totalSeconds = math.max(0, ms) ~/ 1000;
  final minute = totalSeconds ~/ 60;
  final second = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minute:$second';
}

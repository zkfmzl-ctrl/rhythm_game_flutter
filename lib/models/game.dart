part of '../main.dart';

enum NoteKind { aerial, hand, floor, long }

/// The 8 judgement rings arranged around the character, numbered to match
/// the gameplay spec: 1 top, 2 upper-left, 3 upper-right, 4 left (hand),
/// 5 right (hand), 6 lower-left, 7 lower-right, 8 bottom (floor).
const ringOffsets = <int, Offset>{
  1: Offset(0, -1),
  2: Offset(-0.78, -0.68),
  3: Offset(0.78, -0.68),
  4: Offset(-1, 0),
  5: Offset(1, 0),
  6: Offset(-0.78, 0.68),
  7: Offset(0.78, 0.68),
  8: Offset(0, 1),
};

NoteKind kindForRing(int ring) {
  if (ring == 4 || ring == 5) return NoteKind.hand;
  if (ring == 8) return NoteKind.floor;
  return NoteKind.aerial;
}

class RhythmNote {
  RhythmNote({
    required this.id,
    required this.ring,
    required this.hitAt,
    required this.kind,
    this.judged = false,
  });

  final int id;
  final int ring;
  final int hitAt;
  final NoteKind kind;
  bool judged;
}

class GameState {
  GameState({
    required this.notes,
    required this.startedAt,
    required this.durationMs,
  });

  final List<RhythmNote> notes;
  final DateTime startedAt;
  // full length of the audio track; the game only ends once elapsed time
  // reaches this, not whenever the last generated note has been judged.
  final int durationMs;
  int elapsed = -800;
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  bool finished = false;
  Judge? lastJudge;
  // starts far in the past (elapsed begins at -800) so the character isn't
  // shown "knocked back" before any hand note has actually been missed.
  int knockbackUntil = -100000;
  final counts = <Judge, int>{
    Judge.perfect: 0,
    Judge.great: 0,
    Judge.good: 0,
    Judge.miss: 0,
  };
}

/// The default judgement board is 6 rings — 3 up top (1,2,3), 3 down the
/// bottom (6,7,8). Hard mode adds the left/right hand rings (4,5) for 8.
const _order6 = [1, 2, 3, 6, 7, 8];
const _order8 = [1, 4, 5, 2, 3, 8, 6, 7];

List<RhythmNote> buildChart({
  required int seed,
  required int bpm,
  required int durationMs,
  bool hardMode = false,
}) {
  final beat = 60000 / bpm;
  final order = hardMode ? _order8 : _order6;
  final rng = math.Random(seed * 7919 + 13);
  const startAt = 1700;
  final spacing = beat * 0.72;
  // fill the whole track instead of a fixed 42-note burst, leaving a
  // couple seconds of silence at the end before the song itself finishes
  final endAt = math.max(startAt.toDouble(), durationMs - 2000);
  final count = math.max(1, ((endAt - startAt) / spacing).floor());
  // shuffle a repeated pool of rings instead of just cycling the same
  // fixed order, so no two notes in a row are ever too predictable while
  // every ring still gets roughly equal use
  final pool = <int>[];
  while (pool.length < count) {
    final batch = [...order]..shuffle(rng);
    pool.addAll(batch);
  }
  return List.generate(count, (i) {
    final ring = pool[i];
    // long notes land on a random ~1-in-7 note instead of a fixed beat
    final isLong = rng.nextInt(7) == 0;
    return RhythmNote(
      id: i,
      ring: ring,
      hitAt: (startAt + i * spacing).round(),
      kind: isLong ? NoteKind.long : kindForRing(ring),
    );
  });
}

String rankFrom(int score, int maxScore) {
  final ratio = maxScore == 0 ? 0 : score / maxScore;
  if (ratio >= 0.95) return 'S+';
  if (ratio >= 0.88) return 'S';
  if (ratio >= 0.75) return 'A';
  if (ratio >= 0.6) return 'B';
  if (ratio >= 0.45) return 'C';
  return 'D';
}

String judgeText(Judge? judge) {
  switch (judge) {
    case Judge.perfect:
      return 'PERFECT';
    case Judge.great:
      return 'GREAT';
    case Judge.good:
      return 'GOOD';
    case Judge.miss:
      return 'MISS';
    case null:
      return '준비';
  }
}

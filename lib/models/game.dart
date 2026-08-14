part of '../main.dart';

class RhythmNote {
  RhythmNote({
    required this.id,
    required this.lane,
    required this.hitAt,
    required this.long,
    this.judged = false,
  });

  final int id;
  final int lane;
  final int hitAt;
  final bool long;
  bool judged;
}

class GameState {
  GameState({required this.notes, required this.startedAt});

  final List<RhythmNote> notes;
  final DateTime startedAt;
  int elapsed = -800;
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  bool finished = false;
  Judge? lastJudge;
  final counts = <Judge, int>{
    Judge.perfect: 0,
    Judge.great: 0,
    Judge.good: 0,
    Judge.miss: 0,
  };
}

List<RhythmNote> buildChart({required int seed, required int bpm}) {
  final beat = 60000 / bpm;
  return List.generate(42, (i) {
    return RhythmNote(
      id: i,
      lane: (i * 2 + seed) % 5,
      hitAt: (1700 + i * beat * 0.72).round(),
      long: i % 9 == 0,
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

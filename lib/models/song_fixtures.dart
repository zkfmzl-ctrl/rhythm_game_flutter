part of '../main.dart';

const songs = [
  Song(
    id: 1,
    title: '\uB05D\uC744 \uC783\uC5B4\uBC84\uB9B0 \uBC24',
    subtitle: '\uB9AC\uB4EC\uC73C\uB85C \uAE68\uC5B4\uB09C \uB098',
    thumbnailAsset: 'assets/sketch/song-art-large.png',
    bpm: 148,
    durationMs: distortedRhythmDurationMs,
    isLocked: false,
    difficulties: {
      Difficulty.easy: DifficultyInfo(
          level: 2, starRating: 1.5, bestScore: 321450, bestRank: 'B'),
      Difficulty.normal: DifficultyInfo(
          level: 5, starRating: 3, bestScore: 642300, bestRank: 'A'),
      Difficulty.hard: DifficultyInfo(
          level: 8, starRating: 4.5, bestScore: 856200, bestRank: 'S'),
      Difficulty.extreme: DifficultyInfo(
          level: 12, starRating: 5, bestScore: 928900, bestRank: 'S+'),
    },
  ),
  Song(
    id: 2,
    title: '\uC18D\uC0AD\uC784\uC758 \uBBF8\uB85C',
    subtitle: '\uC18D\uC0AD\uC784\uC774 \uD750\uB974\uB294 \uAE38',
    thumbnailAsset: 'assets/sketch/song-art-large.png',
    bpm: 132,
    durationMs: distortedRhythmDurationMs,
    isLocked: true,
    difficulties: {
      Difficulty.easy: DifficultyInfo(level: 3, starRating: 2),
      Difficulty.normal: DifficultyInfo(level: 6, starRating: 3.5),
      Difficulty.hard: DifficultyInfo(level: 9, starRating: 4.5),
      Difficulty.extreme: DifficultyInfo(level: 13, starRating: 5),
    },
  ),
  Song(
    id: 3,
    title: '\uBD80\uC11C\uC9C4 \uAE30\uC5B5',
    subtitle: '\uC870\uAC01\uB09C \uAE30\uC5B5\uC758 \uC794\uD5A5',
    thumbnailAsset: 'assets/sketch/song-art-large.png',
    bpm: 116,
    durationMs: distortedRhythmDurationMs,
    isLocked: true,
    difficulties: {
      Difficulty.easy: DifficultyInfo(level: 2, starRating: 1.5),
      Difficulty.normal: DifficultyInfo(level: 5, starRating: 3),
      Difficulty.hard: DifficultyInfo(level: 8, starRating: 4),
      Difficulty.extreme: DifficultyInfo(level: 11, starRating: 5),
    },
  ),
  Song(
    id: 4,
    title: '\uB05D\uC5C6\uB294 \uD130\uB110',
    subtitle: '\uCD9C\uAD6C \uC5C6\uB294 \uAE34 \uD130\uB110',
    thumbnailAsset: 'assets/sketch/song-art-large.png',
    bpm: 172,
    durationMs: distortedRhythmDurationMs,
    isLocked: true,
    difficulties: {
      Difficulty.easy: DifficultyInfo(level: 4, starRating: 2.5),
      Difficulty.normal: DifficultyInfo(level: 7, starRating: 3.5),
      Difficulty.hard: DifficultyInfo(level: 10, starRating: 4.5),
      Difficulty.extreme: DifficultyInfo(level: 14, starRating: 5),
    },
  ),
  Song(
    id: 5,
    title: '\uCE68\uBB35\uC758 \uC678\uCE68',
    subtitle: '\uCE68\uBB35 \uC18D\uC758 \uB9C8\uC9C0\uB9C9 \uC678\uCE68',
    thumbnailAsset: 'assets/sketch/song-art-large.png',
    bpm: 154,
    durationMs: distortedRhythmDurationMs,
    isLocked: true,
    difficulties: {
      Difficulty.easy: DifficultyInfo(level: 3, starRating: 2),
      Difficulty.normal: DifficultyInfo(level: 6, starRating: 3),
      Difficulty.hard: DifficultyInfo(level: 9, starRating: 4.5),
      Difficulty.extreme: DifficultyInfo(level: 12, starRating: 5),
    },
  ),
];

String diffText(Difficulty difficulty) {
  switch (difficulty) {
    case Difficulty.easy:
      return 'EASY';
    case Difficulty.normal:
      return 'NORMAL';
    case Difficulty.hard:
      return 'HARD';
    case Difficulty.extreme:
      return 'EXTREME';
  }
}

String formatScore(int score) {
  final text = score.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final left = text.length - i;
    buffer.write(text[i]);
    if (left > 1 && left % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String stars(double rating) {
  final full = rating.floor().clamp(0, 5).toInt();
  final half = rating - full >= 0.5;
  final empty = (5 - full - (half ? 1 : 0)).clamp(0, 5).toInt();
  return '${List.filled(full, '*').join()}${half ? '+' : ''}${List.filled(empty, '.').join()}';
}

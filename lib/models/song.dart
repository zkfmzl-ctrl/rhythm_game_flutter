part of '../main.dart';

class Song {
  const Song({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.thumbnailAsset,
    required this.bpm,
    required this.isLocked,
    required this.difficulties,
  });

  final int id;
  final String title;
  final String subtitle;
  final String thumbnailAsset;
  final int bpm;
  final bool isLocked;
  final Map<Difficulty, DifficultyInfo> difficulties;

  bool get unlocked => !isLocked;
  Difficulty get difficulty => Difficulty.hard;
  DifficultyInfo get _primaryInfo => difficulties[difficulty]!;
  int get score => _primaryInfo.bestScore ?? 0;
  String get rank => _primaryInfo.bestRank ?? '-';
}

class DifficultyInfo {
  const DifficultyInfo({
    required this.level,
    required this.starRating,
    this.bestScore,
    this.bestRank,
  });

  final int level;
  final double starRating;
  final int? bestScore;
  final String? bestRank;
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'constants.dart';
part 'models/song.dart';
part 'models/game.dart';
part 'models/character.dart';
part 'models/song_fixtures.dart';
part 'widgets/common_widgets.dart';
part 'screens/home_screen.dart';
part 'screens/song_select_screen.dart';
part 'screens/character_screen.dart';
part 'screens/custom_screen.dart';
part 'screens/quest_screen.dart';
part 'screens/shop_screen.dart';
part 'screens/settings_screen.dart';
part 'screens/play_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const DistortedRhythmApp());
}

class DistortedRhythmApp extends StatelessWidget {
  const DistortedRhythmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '왜곡된 리듬',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff222222)),
        useMaterial3: true,
        fontFamily: 'sans',
      ),
      home: const RhythmGameHome(),
    );
  }
}

class RhythmGameHome extends StatefulWidget {
  const RhythmGameHome({super.key});

  @override
  State<RhythmGameHome> createState() => _RhythmGameHomeState();
}

class _RhythmGameHomeState extends State<RhythmGameHome> {
  AppTab tab = AppTab.home;
  Difficulty difficulty = Difficulty.hard;
  Song selectedSong = songs.first;
  GameState? game;
  Timer? ticker;
  int coins = 12450;
  int gems = 2680;
  String selectedWear = '기본 스크리블';
  double musicVolume = 80;
  double effectVolume = 70;
  double laneSpeed = 1.0;
  bool vibration = true;

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  void startGame() {
    if (selectedSong.isLocked) return;
    ticker?.cancel();
    setState(() {
      game = GameState(
        notes: buildChart(
          seed: selectedSong.id,
          bpm: selectedSong.bpm +
              (difficulty == Difficulty.extreme
                  ? 14
                  : difficulty == Difficulty.easy
                      ? -18
                      : 0),
        ),
        startedAt: DateTime.now().add(const Duration(milliseconds: 800)),
      );
    });
    ticker = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => tickGame(),
    );
  }

  void tickGame() {
    final active = game;
    if (active == null || active.finished) return;
    final elapsed = DateTime.now().difference(active.startedAt).inMilliseconds;
    var missed = 0;
    for (final note in active.notes) {
      if (!note.judged && elapsed - note.hitAt > 280) {
        note.judged = true;
        missed += 1;
      }
    }
    final lastAt = active.notes.map((note) => note.hitAt).reduce(math.max);
    setState(() {
      active.elapsed = elapsed;
      if (missed > 0) {
        active.combo = 0;
        active.counts[Judge.miss] = active.counts[Judge.miss]! + missed;
        active.lastJudge = Judge.miss;
      }
      if (elapsed > lastAt + 1100) {
        active.finished = true;
        ticker?.cancel();
      }
    });
  }

  void hitLane(int lane) {
    final active = game;
    if (active == null || active.finished) return;
    final candidates =
        active.notes.where((note) => !note.judged && note.lane == lane).toList()
          ..sort(
            (a, b) => (active.elapsed - a.hitAt).abs().compareTo(
                  (active.elapsed - b.hitAt).abs(),
                ),
          );
    if (candidates.isEmpty) return;

    final target = candidates.first;
    final distance = (active.elapsed - target.hitAt).abs();
    var judge = Judge.miss;
    var add = 0;
    if (distance <= 55) {
      judge = Judge.perfect;
      add = 100;
    } else if (distance <= 105) {
      judge = Judge.great;
      add = 80;
    } else if (distance <= 170) {
      judge = Judge.good;
      add = 50;
    }

    setState(() {
      target.judged = true;
      if (judge == Judge.miss) {
        active.combo = 0;
      } else {
        active.combo += 1;
        active.maxCombo = math.max(active.maxCombo, active.combo);
      }
      active.score +=
          add + (judge == Judge.miss ? 0 : (active.combo * 1.5).floor());
      active.lastJudge = judge;
      active.counts[judge] = active.counts[judge]! + 1;
    });
  }

  void exitGame() {
    final active = game;
    if (active?.finished == true) {
      coins += (active!.score / 25).floor();
      gems +=
          rankFrom(active.score, active.notes.length * 100) == 'S+' ? 20 : 5;
    }
    ticker?.cancel();
    setState(() {
      game = null;
      tab = AppTab.music;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeGame = game;
    if (activeGame != null) {
      return PlayScreen(
        game: activeGame,
        song: selectedSong,
        difficulty: difficulty,
        onLane: hitLane,
        onReplay: startGame,
        onExit: exitGame,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SketchBackground(
            child: SafeArea(
              left: true,
              right: true,
              top: true,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 54, 18, 84),
                child: currentScreen(),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 14,
            child: SafeArea(
              left: false,
              bottom: false,
              child: CurrencyBar(coins: coins, gems: gems),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomTabs(
              current: tab,
              onTap: (next) => setState(() => tab = next),
            ),
          ),
        ],
      ),
    );
  }

  Widget currentScreen() {
    switch (tab) {
      case AppTab.home:
        return LandscapeHomeScreen(
          onTab: (next) => setState(() => tab = next),
          onStart: startGame,
        );
      case AppTab.music:
        return SongSelectScreen(
          initialSong: selectedSong,
          initialDifficulty: difficulty,
          onSelectSong: (song) => setState(() => selectedSong = song),
          onSelectDifficulty: (next) => setState(() => difficulty = next),
          onStart: startGame,
        );
      case AppTab.character:
        return const CharacterScreen();
      case AppTab.custom:
        return CustomScreen(
          gems: gems,
          selectedWear: selectedWear,
          onEquip: (item) {
            if (item.price <= gems) {
              setState(() {
                gems -= item.price;
                selectedWear = item.name;
              });
            }
          },
        );
      case AppTab.quest:
        return const QuestScreen();
      case AppTab.shop:
        return ShopScreen(
          coins: coins,
          gems: gems,
          onBuy: () => setState(() => coins = math.max(0, coins - 900)),
        );
      case AppTab.settings:
        return SettingsScreen(
          musicVolume: musicVolume,
          effectVolume: effectVolume,
          vibration: vibration,
          laneSpeed: laneSpeed,
          onMusic: (value) => setState(() => musicVolume = value),
          onEffect: (value) => setState(() => effectVolume = value),
          onVibration: (value) => setState(() => vibration = value),
          onLaneSpeed: (value) => setState(() => laneSpeed = value),
        );
    }
  }
}

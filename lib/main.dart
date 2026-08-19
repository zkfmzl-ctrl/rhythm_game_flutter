import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
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
        fontFamily: 'NotoSansKR',
        // the whole UI is scaled through ContainFrame's FittedBox; any
        // widget with a Material elevation shadow (ElevatedButton, Slider
        // thumb) gets its shadow blur magnified by that scale and reads as
        // blurry, so shadows are switched off app-wide.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(elevation: 0),
        ),
        sliderTheme: SliderThemeData(
          thumbShape:
              const RoundSliderThumbShape(elevation: 0, pressedElevation: 0),
          overlayShape: SliderComponentShape.noOverlay,
        ),
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
  Set<int> claimedQuestIds = {};
  Map<String, String> equipped = {
    '헤어': '혼돈의 스크리블',
    '장신구': '랜턴',
    '상의': '그림자 후드',
    '하의': '일자 팬츠',
    '신발': '플랫 슈즈',
    '얼굴': '없음',
  };
  double musicVolume = 80;
  double effectVolume = 70;
  double laneSpeed = 1.0;
  bool vibration = true;
  bool muted = false;
  final _bgm = AudioPlayer();
  final _playTrack = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _bgm
      ..setReleaseMode(ReleaseMode.loop)
      ..setVolume(muted ? 0 : musicVolume / 100)
      ..play(AssetSource('music/background.mp3'));
    _playTrack.setReleaseMode(ReleaseMode.stop);
  }

  void _setMusicVolume(double value) {
    setState(() => musicVolume = value);
    if (!muted) {
      _bgm.setVolume(value / 100);
      _playTrack.setVolume(value / 100);
    }
  }

  void _toggleMute() {
    setState(() => muted = !muted);
    _bgm.setVolume(muted ? 0 : musicVolume / 100);
    _playTrack.setVolume(muted ? 0 : musicVolume / 100);
  }

  @override
  void dispose() {
    ticker?.cancel();
    _bgm.dispose();
    _playTrack.dispose();
    super.dispose();
  }

  void startGame() {
    if (selectedSong.isLocked) return;
    ticker?.cancel();
    // hides the phone's on-screen nav bar (back/home/recents) so it can't
    // overlap the ring board or eat into the play area; restored on exit
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _bgm.pause();
    _playTrack
      ..setVolume(muted ? 0 : musicVolume / 100)
      ..play(AssetSource('music/distorted_rhythm.wav'));
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
          durationMs: selectedSong.durationMs,
          hardMode:
              difficulty == Difficulty.hard || difficulty == Difficulty.extreme,
        ),
        startedAt: DateTime.now().add(const Duration(milliseconds: 800)),
        durationMs: selectedSong.durationMs,
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
    var missedHand = false;
    for (final note in active.notes) {
      if (!note.judged && elapsed - note.hitAt > 280) {
        note.judged = true;
        missed += 1;
        if (note.kind == NoteKind.hand) missedHand = true;
      }
    }
    setState(() {
      active.elapsed = elapsed;
      if (missed > 0) {
        active.combo = 0;
        active.counts[Judge.miss] = active.counts[Judge.miss]! + missed;
        active.lastJudge = Judge.miss;
        if (missedHand) active.knockbackUntil = elapsed + 450;
      }
      // the game runs until the song itself ends, not just until the last
      // generated note has been judged
      if (elapsed >= active.durationMs) {
        active.finished = true;
        ticker?.cancel();
      }
    });
  }

  void hitRing(int ring) {
    final active = game;
    if (active == null || active.finished) return;
    final candidates =
        active.notes.where((note) => !note.judged && note.ring == ring).toList()
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
        // a whiffed hand note pushes the character back, per the spec's
        // knockback penalty for hand notes
        if (target.kind == NoteKind.hand) {
          active.knockbackUntil = active.elapsed + 450;
        }
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _playTrack.stop();
    _bgm.resume();
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
        onRing: hitRing,
        onReplay: startGame,
        onExit: exitGame,
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Decorative background sits outside SafeArea and fills the real
          // physical screen edge-to-edge (its own Stack, not the 1300x600
          // ContainFrame canvas). Devices with a camera cutout/curved edge
          // in landscape (e.g. this session's test phone) inset SafeArea on
          // one side only; wrapping the background in that SafeArea left a
          // permanent blank margin down that whole side instead of true
          // full-bleed art, since decorative art doesn't need protecting
          // from the cutout the way tappable/text content does.
          const Positioned.fill(child: _AppBackdrop()),
          // SafeArea (real device insets: notch, status bar, gesture nav) is
          // applied once, outermost, in real pixels. Everything inside it —
          // page content, currency bar, bottom tabs — shares a single
          // ContainFrame, so they all scale together by the same factor.
          // Previously the currency bar and bottom tabs sat outside any
          // ContainFrame at native pixel size, so shrinking the window
          // shrank the page content but left them the same size — making
          // them look proportionally *bigger* as the window got smaller.
          SafeArea(
            child: ContainFrame(
              child: Stack(
                children: [
                  Padding(
                    // BottomTabs (67px incl. its border) is a separate
                    // overlay drawn on top of this content, not room the
                    // layout below reserves on its own.
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18 + 67),
                    child: currentScreen(),
                  ),
                  if (tab != AppTab.settings)
                    Positioned(
                      top: 10,
                      right: 14,
                      child: CurrencyBar(
                        coins: coins,
                        gems: gems,
                        onTap: () => setState(() => tab = AppTab.shop),
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
          equipped: equipped,
          onEquip: (item) {
            if (item.unlockCondition != null) return;
            if (item.price > gems) return;
            setState(() {
              gems -= item.price;
              equipped[item.slot] = item.name;
            });
          },
        );
      case AppTab.quest:
        return QuestScreen(
          claimedIds: claimedQuestIds,
          onClaim: (quest) => setState(() {
            claimedQuestIds.add(quest.id);
            coins += quest.reward;
          }),
          onGoTo: (quest) => setState(() {
            tab = quest.title.contains('상점') ? AppTab.shop : AppTab.music;
          }),
        );
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
          muted: muted,
          onMusic: _setMusicVolume,
          onEffect: (value) => setState(() => effectVolume = value),
          onVibration: (value) => setState(() => vibration = value),
          onLaneSpeed: (value) => setState(() => laneSpeed = value),
          onMuteToggle: _toggleMute,
        );
    }
  }
}

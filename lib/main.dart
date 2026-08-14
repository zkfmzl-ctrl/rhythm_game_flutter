import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const DistortedRhythmApp());
}

enum AppTab { home, music, character, custom, quest, shop, settings }

enum Difficulty { easy, normal, hard, extreme }

enum Judge { perfect, great, good, miss }

const perspectiveInspectionMode = true;
const boardTopY = 0.49;
const boardBottomY = 1.0;
const vanishX = 0.5385;
const vanishY = 0.466;
const floorLeftX = 0.04;
const floorRightX = 0.96;
const playHudTop = 112.0;

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

class SketchBackground extends StatelessWidget {
  const SketchBackground({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xffd3d0c5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffc5c2b8), Color(0xffece9de), Color(0xffbbb8af)],
        ),
      ),
      child: CustomPaint(
        painter: PaperScratchPainter(),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class PaperScratchPainter extends CustomPainter {
  const PaperScratchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.055)
      ..strokeWidth = 1;
    for (var i = 0; i < 54; i += 1) {
      final x = (i * 37) % size.width;
      final y = (i * 71) % size.height;
      canvas.drawLine(Offset(x - 42, y), Offset(x + 120, y + 44), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {this.subtitle, super.key});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 38,
              height: 1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}

class PaperPanel extends StatelessWidget {
  const PaperPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xffe5e2d7).withValues(alpha: 0.94),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            offset: Offset(3, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return panel;
    return InkWell(onTap: onTap, child: panel);
  }
}

class CurrencyBar extends StatelessWidget {
  const CurrencyBar({required this.coins, required this.gems, super.key});
  final int coins;
  final int gems;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.toll, size: 18),
          const SizedBox(width: 3),
          Text(coins.toString(),
              style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          const MiniBox('+'),
          const SizedBox(width: 8),
          const Icon(Icons.diamond, size: 18),
          const SizedBox(width: 3),
          Text(gems.toString(),
              style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          const MiniBox('+'),
        ],
      ),
    );
  }
}

class MiniBox extends StatelessWidget {
  const MiniBox(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(width: 2),
        color: const Color(0xffeeeade),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onTab, required this.onStart, super.key});
  final ValueChanged<AppTab> onTab;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) =>
      LandscapeHomeScreen(onTab: onTab, onStart: onStart);
}

class _HomeAction {
  const _HomeAction(this.title, this.subtitle, this.icon, this.onTap);

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class LandscapeHomeScreen extends StatelessWidget {
  const LandscapeHomeScreen(
      {required this.onTab, required this.onStart, super.key});
  final ValueChanged<AppTab> onTab;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _HomeAction('게임 시작', '리듬의 세계로 들어가기', Icons.play_arrow, onStart),
      _HomeAction(
          '곡 선택', '곡을 선택하고 플레이', Icons.music_note, () => onTab(AppTab.music)),
      _HomeAction('캐릭터', '캐릭터 확인 및 변경', Icons.person_pin,
          () => onTab(AppTab.character)),
      _HomeAction(
          '꾸미기', '의상과 이펙트 변경', Icons.checkroom, () => onTab(AppTab.custom)),
      _HomeAction(
          '퀘스트', '임무를 완료하고 보상 받기', Icons.fact_check, () => onTab(AppTab.quest)),
      _HomeAction(
          '상점', '아이템과 패키지 구매', Icons.shopping_cart, () => onTab(AppTab.shop)),
      _HomeAction(
          '설정', '게임 환경 설정', Icons.settings, () => onTab(AppTab.settings)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageTitle('왜곡된 리듬', subtitle: '리듬으로 깨어난 나'),
                  Expanded(
                    child: PaperPanel(
                      padding: EdgeInsets.zero,
                      child: ClipRect(
                        child: Image.asset(
                          'assets/sketch/home-character.png',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const PaperPanel(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('공지\n새로운 곡과 임무를 확인하세요.',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 58,
              child: GridView.builder(
                itemCount: actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 92,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) =>
                    _LandscapeActionButton(item: actions[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LandscapeActionButton extends StatelessWidget {
  const _LandscapeActionButton({required this.item});
  final _HomeAction item;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      onTap: item.onTap,
      child: Row(
        children: [
          Icon(item.icon, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                Text(item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SongSelectScreen extends StatefulWidget {
  const SongSelectScreen({
    required this.initialSong,
    required this.initialDifficulty,
    required this.onSelectSong,
    required this.onSelectDifficulty,
    required this.onStart,
    super.key,
  });

  final Song initialSong;
  final Difficulty initialDifficulty;
  final ValueChanged<Song> onSelectSong;
  final ValueChanged<Difficulty> onSelectDifficulty;
  final VoidCallback onStart;

  @override
  State<SongSelectScreen> createState() => _SongSelectScreenState();
}

class _SongSelectScreenState extends State<SongSelectScreen> {
  late Song _selected;
  late Difficulty _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSong;
    _selectedDifficulty = widget.initialDifficulty;
  }

  @override
  void didUpdateWidget(covariant SongSelectScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSong.id != oldWidget.initialSong.id) {
      _selected = widget.initialSong;
    }
    if (widget.initialDifficulty != oldWidget.initialDifficulty) {
      _selectedDifficulty = widget.initialDifficulty;
    }
  }

  void _selectSong(Song song) {
    setState(() => _selected = song);
    widget.onSelectSong(song);
  }

  void _selectDifficulty(Difficulty difficulty) {
    setState(() => _selectedDifficulty = difficulty);
    widget.onSelectDifficulty(difficulty);
  }

  void _start() {
    if (_selected.isLocked) return;
    widget.onSelectSong(_selected);
    widget.onSelectDifficulty(_selectedDifficulty);
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    final info = _selected.difficulties[_selectedDifficulty]!;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/backgrounds/main.png', fit: BoxFit.cover),
        Container(color: Colors.white.withValues(alpha: 0.58)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageTitle('\uACE1 \uC120\uD0DD',
                subtitle:
                    '\uACE1\uACFC \uB09C\uC774\uB3C4\uB97C \uC120\uD0DD\uD558\uC138\uC694'),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 47,
                    child: PaperPanel(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('\uACE1 \uBAA9\uB85D',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w900)),
                              MiniBox('5\uACE1'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: songs.length,
                              itemBuilder: (context, index) {
                                final song = songs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _SongSelectTile(
                                    song: song,
                                    selected: song.id == _selected.id,
                                    frameAsset:
                                        'assets/buttons/box_${(index + 1).toString().padLeft(2, '0')}.png',
                                    onTap: () => _selectSong(song),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 53,
                    child: _SongDetailPanel(
                      song: _selected,
                      difficulty: _selectedDifficulty,
                      info: info,
                      onDifficulty: _selectDifficulty,
                      onStart: _start,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SongSelectTile extends StatelessWidget {
  const _SongSelectTile({
    required this.song,
    required this.selected,
    required this.frameAsset,
    required this.onTap,
  });

  final Song song;
  final bool selected;
  final String frameAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = song.difficulties[Difficulty.hard]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          border: selected
              ? Border.all(color: Colors.black, width: 3)
              : Border.all(
                  color: Colors.black.withValues(alpha: 0.28), width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(frameAsset, fit: BoxFit.fill),
            ColoredBox(
              color: song.isLocked
                  ? const Color(0xcce8e4d8)
                  : const Color(0xdffff8e7),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: ColorFiltered(
                      colorFilter: song.isLocked
                          ? const ColorFilter.mode(
                              Color(0x88000000),
                              BlendMode.srcATop,
                            )
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                      child: Image.asset(song.thumbnailAsset,
                          width: 58, height: 58, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xfffff8e7),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                '${song.id.toString().padLeft(2, '0')}. ${song.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xff050505),
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 2,
                                        offset: Offset(0, 1),
                                      ),
                                    ])),
                            const SizedBox(height: 3),
                            Text(
                                '${song.subtitle} - BPM ${song.bpm} - Lv.${info.level}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xff252525),
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (song.isLocked)
                    const Icon(Icons.lock, size: 19)
                  else
                    Text(info.bestRank ?? '-',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongDetailPanel extends StatelessWidget {
  const _SongDetailPanel({
    required this.song,
    required this.difficulty,
    required this.info,
    required this.onDifficulty,
    required this.onStart,
  });

  final Song song;
  final Difficulty difficulty;
  final DifficultyInfo info;
  final ValueChanged<Difficulty> onDifficulty;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.asset(song.thumbnailAsset,
                      width: 76, height: 76, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900)),
                      Text(song.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('BPM ${song.bpm}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                if (song.isLocked) const Icon(Icons.lock, size: 32),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: Difficulty.values.map((item) {
                final selected = item == difficulty;
                final itemInfo = song.difficulties[item]!;
                final index = Difficulty.values.indexOf(item) + 6;
                return _DifficultyButton(
                  label: diffText(item),
                  subLabel:
                      'Lv.${itemInfo.level}  ${stars(itemInfo.starRating)}',
                  asset:
                      'assets/buttons/box_${index.toString().padLeft(2, '0')}.png',
                  selected: selected,
                  onTap: () => onDifficulty(item),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: LabeledValue(
                        '\uCD5C\uACE0\uC810\uC218',
                        info.bestScore == null
                            ? '-'
                            : formatScore(info.bestScore!))),
                const SizedBox(width: 8),
                Expanded(
                    child: LabeledValue('\uB7AD\uD06C', info.bestRank ?? '-')),
              ],
            ),
            const SizedBox(height: 8),
            PaperPanel(
              padding: const EdgeInsets.all(9),
              child: Text(
                  '난이도 ${diffText(difficulty)} · 레벨 ${info.level} · 별점 ${info.starRating.toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 10),
            _StartButton(enabled: !song.isLocked, onTap: onStart),
          ],
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({
    required this.label,
    required this.subLabel,
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subLabel;
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 116,
        height: 50,
        decoration:
            BoxDecoration(border: Border.all(width: selected ? 3 : 1.5)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(asset, fit: BoxFit.fill),
            Container(
                color: selected
                    ? Colors.black.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.35)),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w900)),
                Text(subLabel,
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: SizedBox(
          height: 58,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/buttons/box_20.png', fit: BoxFit.fill),
              Center(
                  child: Text(
                      enabled ? '\uC2DC\uC791\uD558\uAE30' : '\uC7A0\uAE40',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900))),
            ],
          ),
        ),
      ),
    );
  }
}

class MusicScreen extends StatelessWidget {
  const MusicScreen({
    required this.selectedSong,
    required this.difficulty,
    required this.onDifficulty,
    required this.onSelectSong,
    required this.onStart,
    super.key,
  });

  final Song selectedSong;
  final Difficulty difficulty;
  final ValueChanged<Difficulty> onDifficulty;
  final ValueChanged<Song> onSelectSong;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SongSelectScreen(
      initialSong: selectedSong,
      initialDifficulty: difficulty,
      onSelectSong: onSelectSong,
      onSelectDifficulty: onDifficulty,
      onStart: onStart,
    );
  }
}

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final characters = ['노아', '리마', '아이'].asMap().entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('캐릭터', subtitle: '리듬 공명'),
        Expanded(
          child: ListView.builder(
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final entry = characters[index];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == characters.length - 1 ? 0 : 12),
                child: SizedBox(
                  height: 140,
                  child: PaperPanel(
                    child: Row(
                      children: [
                        Image.asset(
                            entry.key == 0
                                ? 'assets/sketch/character-card.png'
                                : 'assets/sketch/song-thumb-2.png',
                            width: 86,
                            height: 104,
                            fit: BoxFit.cover),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900)),
                              Text(entry.key == 0 ? '선택 중' : '잠김',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                  '체력 ${80 + entry.key * 8} · 리듬 감응력 ${70 + entry.key * 10}\n이동 속도 ${60 + entry.key * 6} · 집중력 ${50 + entry.key * 8}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12)),
                              const Text('고유 능력: 리듬 공명',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        if (entry.key > 0) const Icon(Icons.lock),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CustomScreen extends StatelessWidget {
  const CustomScreen({
    required this.gems,
    required this.selectedWear,
    required this.onEquip,
    super.key,
  });
  final int gems;
  final String selectedWear;
  final ValueChanged<WearItem> onEquip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('꾸미기', subtitle: '착용 중 아이템'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 43,
              child: PaperPanel(
                child: Column(
                  children: [
                    Image.asset('assets/sketch/wardrobe-preview.png',
                        height: 270, fit: BoxFit.cover),
                    const SizedBox(height: 8),
                    const Text('착용 중 아이템',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                        '헤어: $selectedWear\n장신구: 기본 장신구\n상의: 기본 상의\n하의: 기본 하의\n신발: 기본 신발\n얼굴: 기본 얼굴'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 57,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: wardrobe
                    .map((item) => SizedBox(
                          width: 108,
                          child: PaperPanel(
                            onTap: () =>
                                item.price <= gems ? onEquip(item) : null,
                            child: Column(
                              children: [
                                Image.asset('assets/sketch/song-thumb-2.png',
                                    width: 46, height: 38, fit: BoxFit.cover),
                                Text(item.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900)),
                                Text(selectedWear == item.name
                                    ? '장착 해제'
                                    : item.owned
                                        ? '장착하기'
                                        : '${item.price}'),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('퀘스트', subtitle: '데일리'),
        const Row(
          children: [
            _QuestFilter('데일리'),
            SizedBox(width: 8),
            _QuestFilter('위클리'),
            SizedBox(width: 8),
            _QuestFilter('업적'),
            SizedBox(width: 8),
            _QuestFilter('모두 받기'),
          ],
        ),
        const SizedBox(height: 12),
        ...quests.map((quest) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PaperPanel(
                child: Row(
                  children: [
                    Icon(quest.done ? Icons.check_circle : Icons.star,
                        size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text('${quest.title}\n${quest.progress}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w800))),
                    ElevatedButton(
                        onPressed: quest.done ? () {} : null,
                        child: Text(quest.done ? '보상 받기' : '바로 가기')),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _QuestFilter extends StatelessWidget {
  const _QuestFilter(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class ShopScreen extends StatelessWidget {
  const ShopScreen({
    required this.coins,
    required this.gems,
    required this.onBuy,
    super.key,
  });
  final int coins;
  final int gems;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    const packs = ['추천', '장비/효과', '묶음 상품', '재화', '꾸미기'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('상점', subtitle: '추천'),
        PaperPanel(
          child: Column(
            children: [
              Image.asset('assets/sketch/shop-grid.png',
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter),
              Text('재화: $coins / $gems',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: packs
              .asMap()
              .entries
              .map((entry) => SizedBox(
                    width: 120,
                    child: PaperPanel(
                      onTap: onBuy,
                      child: Column(
                        children: [
                          Image.asset('assets/sketch/song-thumb-1.png',
                              width: 50, height: 42, fit: BoxFit.cover),
                          Text(entry.value,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900)),
                          Text(entry.key.isEven
                              ? '${(entry.key + 1) * 300}'
                              : '${(entry.key + 1) * 200}'),
                          ElevatedButton(
                              onPressed: onBuy, child: const Text('구매')),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.musicVolume,
    required this.effectVolume,
    required this.vibration,
    required this.laneSpeed,
    required this.onMusic,
    required this.onEffect,
    required this.onVibration,
    required this.onLaneSpeed,
    super.key,
  });
  final double musicVolume;
  final double effectVolume;
  final bool vibration;
  final double laneSpeed;
  final ValueChanged<double> onMusic;
  final ValueChanged<double> onEffect;
  final ValueChanged<bool> onVibration;
  final ValueChanged<double> onLaneSpeed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('설정', subtitle: '게임 환경 설정'),
        SettingSlider(label: '음악 볼륨', value: musicVolume, onChanged: onMusic),
        SettingSlider(
          label: '효과음 볼륨',
          value: effectVolume,
          onChanged: onEffect,
        ),
        PaperPanel(
          child: SwitchListTile(
            title: const Text(
              '진동',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            value: vibration,
            onChanged: onVibration,
          ),
        ),
        const SizedBox(height: 12),
        PaperPanel(
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '노트 속도',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: () => onLaneSpeed(math.max(0.5, laneSpeed - 0.1)),
                icon: const Icon(Icons.remove),
              ),
              Text(
                '${laneSpeed.toStringAsFixed(1)}x',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              IconButton(
                onPressed: () => onLaneSpeed(math.min(2.0, laneSpeed + 0.1)),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const PaperPanel(
          child: Text('판정 보조', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        const PaperPanel(
          child:
              Text('그래픽/배경 효과', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 12),
        const PaperPanel(
          child: Text('데이터 초기화', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class SettingSlider extends StatelessWidget {
  const SettingSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PaperPanel(
        child: Row(
          children: [
            SizedBox(
              width: 86,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: 0,
                max: 100,
                onChanged: onChanged,
              ),
            ),
            Text('${value.round()}%'),
          ],
        ),
      ),
    );
  }
}

class PlayScreen extends StatelessWidget {
  const PlayScreen({
    required this.game,
    required this.song,
    required this.difficulty,
    required this.onLane,
    required this.onReplay,
    required this.onExit,
    super.key,
  });

  final GameState game;
  final Song song;
  final Difficulty difficulty;
  final ValueChanged<int> onLane;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final rank = rankFrom(game.score, game.notes.length * 100);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          Image.asset('assets/backgrounds/play.png', fit: BoxFit.cover),
          FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: 1600,
              height: 900,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final lane = _laneFromPoint(
                          details.localPosition,
                          const Size(1600, 900),
                        );
                        if (lane != null) onLane(lane);
                      },
                      child: const NoteBoardLayer(),
                    ),
                  ),
                  MovingNotesLayer(game: game),
                  JudgementLayer(game: game),
                  const Positioned(
                    left: 118,
                    top: 180,
                    width: 255,
                    height: 535,
                    child: _PlayCharacterLayer(),
                  ),
                  Positioned(
                    left: 34,
                    top: playHudTop,
                    width: 470,
                    child: _SongHud(song: song, difficulty: difficulty),
                  ),
                  Positioned(
                    left: 740,
                    top: playHudTop + 8,
                    width: 420,
                    child: _ProgressBar(game: game),
                  ),
                  Positioned(
                    right: 50,
                    top: playHudTop,
                    width: 260,
                    child: _ScoreHud(game: game, rank: rank, onExit: onExit),
                  ),
                  Positioned(
                    left: 32,
                    bottom: 26,
                    width: 240,
                    child: _JudgeHud(game: game),
                  ),
                  if (game.finished)
                    Center(
                      child: PaperPanel(
                        padding: const EdgeInsets.all(18),
                        child: SizedBox(
                          width: 360,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                rank,
                                style: const TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${song.title} 클리어',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '점수 ${game.score}\n최대 콤보 ${game.maxCombo}\nPERFECT ${game.counts[Judge.perfect]} · MISS ${game.counts[Judge.miss]}',
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: onReplay,
                                      child: const Text('다시하기'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: onExit,
                                      child: const Text('곡 선택으로'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final last = game.notes.isEmpty
        ? 1
        : game.notes.map((note) => note.hitAt).reduce(math.max);
    final progress = (game.elapsed / math.max(last, 1)).clamp(0.0, 1.0);
    final elapsedSeconds = math.max(0, game.elapsed ~/ 1000);
    final minute = elapsedSeconds ~/ 60;
    final second = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 28,
          child: CustomPaint(painter: _ProgressPainter(progress: progress)),
        ),
        Text(
          '$minute:$second / 1:34',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class NoteBoardLayer extends StatelessWidget {
  const NoteBoardLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: CustomPaint(painter: _PerspectiveLanePainter())),
        Positioned(
          left: 485,
          right: 105,
          bottom: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (lane) {
              return CustomPaint(
                size: const Size(86, 48),
                painter: _HitPadPainter(active: lane == 1 || lane == 2),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class MovingNotesLayer extends StatelessWidget {
  const MovingNotesLayer({required this.game, super.key});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    const stageSize = Size(1600, 900);
    return Stack(
      children: game.notes.where((note) => !note.judged).map((note) {
        final p = ((game.elapsed - (note.hitAt - 1350)) / 1350).clamp(
          -0.25,
          1.1,
        );
        if (p < -0.1 || p > 1.05) return const SizedBox.shrink();
        final point = _lanePoint(stageSize, note.lane, p);
        final scale = 0.45 + p * 0.9;
        return Positioned(
          left: point.dx - 18 * scale,
          top: point.dy - (note.long ? 60 : 18) * scale,
          child: _PlayNoteShape(lane: note.lane, long: note.long, scale: scale),
        );
      }).toList(),
    );
  }
}

class JudgementLayer extends StatelessWidget {
  const JudgementLayer({required this.game, super.key});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 630,
      top: 520,
      width: 460,
      child: IgnorePointer(
        child: Column(
          children: [
            Text(
              judgeText(game.lastJudge),
              style: TextStyle(
                fontSize: 58,
                height: 0.95,
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${math.max(game.combo, 47)} COMBO',
              style: TextStyle(
                fontSize: 30,
                color: Colors.white.withValues(alpha: 0.74),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayCharacterLayer extends StatelessWidget {
  const _PlayCharacterLayer();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/character/character_01.png',
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
    );
  }
}

class _SongHud extends StatelessWidget {
  const _SongHud({required this.song, required this.difficulty});
  final Song song;
  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Image.asset(song.thumbnailAsset,
              width: 74, height: 74, fit: BoxFit.cover),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _DarkTag(diffText(difficulty)),
                    const SizedBox(width: 14),
                    Text(
                      'BPM  ${song.bpm}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreHud extends StatelessWidget {
  const _ScoreHud(
      {required this.game, required this.rank, required this.onExit});
  final GameState game;
  final String rank;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${game.score}',
                      style: const TextStyle(
                          fontSize: 40,
                          height: 0.95,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('${game.combo}',
                      style: const TextStyle(
                          fontSize: 44,
                          height: 0.9,
                          fontWeight: FontWeight.w900)),
                  Text(
                    'COMBO',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onExit,
              child: PaperPanel(
                padding: const EdgeInsets.all(13),
                child: Icon(
                  Icons.pause,
                  size: 42,
                  color: Colors.black.withValues(alpha: 0.92),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        PaperPanel(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('현재 등급',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Center(
                child: Text(rank,
                    style: const TextStyle(
                        fontSize: 74, fontWeight: FontWeight.w900)),
              ),
              const _RankGauge(percent: 0.84),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('84%',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 10),
              const Text('다음 등급',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const Row(
                children: [
                  Text('S+',
                      style:
                          TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                  SizedBox(width: 18),
                  Text('100%',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JudgeHud extends StatelessWidget {
  const _JudgeHud({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          _JudgeCount(
              symbol: 'O',
              label: 'PERFECT',
              count: game.counts[Judge.perfect]!),
          _JudgeCount(
              symbol: 'A', label: 'GREAT', count: game.counts[Judge.great]!),
          _JudgeCount(
              symbol: 'D', label: 'GOOD', count: game.counts[Judge.good]!),
          _JudgeCount(
              symbol: 'X', label: 'MISS', count: game.counts[Judge.miss]!),
        ],
      ),
    );
  }
}

class _DarkTag extends StatelessWidget {
  const _DarkTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      color: Colors.black,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xffe9e4d8),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _JudgeCount extends StatelessWidget {
  const _JudgeCount({
    required this.symbol,
    required this.label,
    required this.count,
  });
  final String symbol;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              symbol,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _RankGauge extends StatelessWidget {
  const _RankGauge({required this.percent});
  final double percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      width: double.infinity,
      child: CustomPaint(painter: _RankGaugePainter(percent: percent)),
    );
  }
}

class _PlayNoteShape extends StatelessWidget {
  const _PlayNoteShape({
    required this.lane,
    required this.long,
    required this.scale,
  });
  final int lane;
  final bool long;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = Size(42 * scale, (long ? 130 : 42) * scale);
    return CustomPaint(
      size: size,
      painter: _NoteShapePainter(lane: lane, long: long),
    );
  }
}

int? _laneFromPoint(Offset point, Size size) {
  final normalizedY = point.dy / size.height;
  if (normalizedY < boardTopY || normalizedY > boardBottomY) {
    return null;
  }
  final progress =
      ((normalizedY - boardTopY) / (boardBottomY - boardTopY)).clamp(0.0, 1.0);
  final normalizedX = point.dx / size.width;
  final left = _perspectiveXAtProgress(floorLeftX, progress);
  final right = _perspectiveXAtProgress(floorRightX, progress);
  final normalized = (normalizedX - left) / (right - left);
  if (normalized < 0 || normalized > 1) return null;
  return (normalized * 5).floor().clamp(0, 4);
}

Offset _lanePoint(Size size, int lane, double progress) {
  final y = size.height * _boardYAtProgress(progress);
  final left = _perspectiveXAtProgress(floorLeftX, progress);
  final right = _perspectiveXAtProgress(floorRightX, progress);
  final laneWidth = (right - left) / 5;
  return Offset(size.width * (left + laneWidth * (lane + 0.5)), y);
}

double _boardYAtProgress(double progress) {
  return boardTopY + (boardBottomY - boardTopY) * progress;
}

double _perspectiveXAtProgress(double floorX, double progress) {
  final topX = _perspectiveXAtY(floorX, boardTopY);
  return topX + (floorX - topX) * progress;
}

double _perspectiveXAtY(double floorX, double y) {
  final t = (y - vanishY) / (boardBottomY - vanishY);
  return vanishX + (floorX - vanishX) * t;
}

class _PerspectiveLanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topLeft = _perspectiveXAtY(floorLeftX, boardTopY);
    final topRight = _perspectiveXAtY(floorRightX, boardTopY);
    final board = Path()
      ..moveTo(size.width * topLeft, size.height * boardTopY)
      ..lineTo(size.width * topRight, size.height * boardTopY)
      ..lineTo(size.width * floorRightX, size.height * boardBottomY)
      ..lineTo(size.width * floorLeftX, size.height * boardBottomY)
      ..close();
    canvas.drawPath(
      board,
      Paint()..color = const Color(0xff1f1f1d).withValues(alpha: 0.9),
    );
    canvas.drawPath(
      board,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.black,
    );

    final lanePaint = Paint()
      ..color = const Color(0xffd6d0c2).withValues(alpha: 0.55)
      ..strokeWidth = 2;
    for (var i = 0; i <= 5; i += 1) {
      final p = i / 5;
      final top = Offset(
        size.width * (topLeft + (topRight - topLeft) * p),
        size.height * boardTopY,
      );
      final bottom = Offset(
        size.width * (floorLeftX + (floorRightX - floorLeftX) * p),
        size.height * boardBottomY,
      );
      canvas.drawLine(top, bottom, lanePaint);
    }

    final scratch = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 0; i < 42; i += 1) {
      final y = size.height * ((i * 31) % 100) / 100;
      canvas.drawLine(
        Offset(size.width * (0.16 + (i % 5) * 0.14), y),
        Offset(size.width * (0.22 + (i % 5) * 0.16), y + 24),
        scratch,
      );
    }

    canvas.drawLine(
      Offset(size.width * 0.04, size.height * 0.82),
      Offset(size.width * 0.96, size.height * 0.82),
      Paint()
        ..color = const Color(0xffe8e4d8)
        ..strokeWidth = 4,
    );

    if (perspectiveInspectionMode) {
      BoardOutlinePainter().paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BoardOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topLeft = _perspectiveXAtY(floorLeftX, boardTopY);
    final topRight = _perspectiveXAtY(floorRightX, boardTopY);
    final outline = Path()
      ..moveTo(size.width * topLeft, size.height * boardTopY)
      ..lineTo(size.width * topRight, size.height * boardTopY)
      ..lineTo(size.width * floorRightX, size.height * boardBottomY)
      ..lineTo(size.width * floorLeftX, size.height * boardBottomY)
      ..close();

    final boundaryPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.redAccent;
    canvas.drawPath(outline, boundaryPaint);

    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.redAccent.withValues(alpha: 0.72);
    for (var i = 1; i < 5; i += 1) {
      final p = i / 5;
      canvas.drawLine(
        Offset(
          size.width * (topLeft + (topRight - topLeft) * p),
          size.height * boardTopY,
        ),
        Offset(
          size.width * (floorLeftX + (floorRightX - floorLeftX) * p),
          size.height * boardBottomY,
        ),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final border = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(0),
    );
    canvas.drawRRect(border, Paint()..color = const Color(0xffd6d0c2));
    canvas.drawRRect(
      border.deflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black,
    );
    canvas.drawRect(
      Rect.fromLTWH(7, 8, (size.width - 14) * progress, size.height - 16),
      Paint()..color = Colors.black.withValues(alpha: 0.84),
    );
    final scratch = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var x = 12.0; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, size.height - 6), Offset(x + 24, 6), scratch);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RankGaugePainter extends CustomPainter {
  const _RankGaugePainter({required this.percent});
  final double percent;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 6, size.width, 12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black,
    );
    canvas.drawRect(
      Rect.fromLTWH(1, y - 5, (size.width - 2) * percent, 10),
      Paint()..color = Colors.black.withValues(alpha: 0.88),
    );
    final markerX = (size.width - 2) * percent;
    final marker = Path()
      ..moveTo(markerX, y + 12)
      ..lineTo(markerX - 7, y + 25)
      ..lineTo(markerX + 7, y + 25)
      ..close();
    canvas.drawPath(marker, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant _RankGaugePainter oldDelegate) =>
      oldDelegate.percent != percent;
}

class _HitPadPainter extends CustomPainter {
  const _HitPadPainter({required this.active});
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 4; i += 1) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: size.width - i * 12,
          height: size.height - i * 7,
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 0 ? 3 : 1.5
          ..color = active && i == 0 ? Colors.white : Colors.black,
      );
    }
    if (active) {
      final burst = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = 2;
      for (var i = 0; i < 12; i += 1) {
        final a = i * math.pi / 6;
        canvas.drawLine(
          center,
          center + Offset(math.cos(a), math.sin(a)) * 33,
          burst,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HitPadPainter oldDelegate) =>
      oldDelegate.active != active;
}

class _NoteShapePainter extends CustomPainter {
  const _NoteShapePainter({required this.lane, required this.long});
  final int lane;
  final bool long;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xffeee9dc);
    final fill = Paint()..color = Colors.black.withValues(alpha: 0.72);
    if (long) {
      final lineX = size.width / 2;
      canvas.drawLine(
        Offset(lineX, 8),
        Offset(lineX, size.height - 20),
        paint..strokeWidth = 5,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lineX, 14),
          width: size.width * 0.72,
          height: size.width * 0.34,
        ),
        fill,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lineX, 14),
          width: size.width * 0.72,
          height: size.width * 0.34,
        ),
        paint..strokeWidth = 3,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lineX, size.height - 18),
          width: size.width,
          height: size.width * 0.55,
        ),
        fill,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(lineX, size.height - 18),
          width: size.width,
          height: size.width * 0.55,
        ),
        paint,
      );
      return;
    }
    if (lane == 2) {
      final tri = Path()
        ..moveTo(size.width / 2, 3)
        ..lineTo(size.width - 4, size.height - 5)
        ..lineTo(4, size.height - 5)
        ..close();
      canvas.drawPath(tri, fill);
      canvas.drawPath(tri, paint);
      return;
    }
    if (lane == 4) {
      canvas.drawRect(
        Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
        fill,
      );
      canvas.drawRect(
        Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
        paint,
      );
      return;
    }
    canvas.drawOval(
      Rect.fromLTWH(2, 7, size.width - 4, size.height - 14),
      fill,
    );
    canvas.drawOval(
      Rect.fromLTWH(2, 7, size.width - 4, size.height - 14),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(11, 14, size.width - 22, size.height - 28),
      paint..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _NoteShapePainter oldDelegate) =>
      oldDelegate.lane != lane || oldDelegate.long != long;
}

class LabeledValue extends StatelessWidget {
  const LabeledValue(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class BottomTabs extends StatelessWidget {
  const BottomTabs({required this.current, required this.onTap, super.key});
  final AppTab current;
  final ValueChanged<AppTab> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (AppTab.home, '홈', Icons.home),
      (AppTab.music, '곡 선택', Icons.music_note),
      (AppTab.character, '캐릭터', Icons.person_pin),
      (AppTab.custom, '꾸미기', Icons.checkroom),
      (AppTab.quest, '퀘스트', Icons.fact_check),
      (AppTab.shop, '상점', Icons.shopping_cart),
      (AppTab.settings, '설정', Icons.settings),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.map((item) {
            final active = current == item.$1;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(item.$1),
                child: Container(
                  height: 64,
                  color: active ? const Color(0xffe9e4d8) : Colors.black,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$3,
                        color: active ? Colors.black : const Color(0xffe8e4d8),
                        size: 23,
                      ),
                      Text(
                        item.$2,
                        style: TextStyle(
                          color:
                              active ? Colors.black : const Color(0xffe8e4d8),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class WearItem {
  const WearItem(this.name, this.price, this.owned);
  final String name;
  final int price;
  final bool owned;
}

class Quest {
  const Quest(this.title, this.reward, this.progress, this.done);
  final String title;
  final String reward;
  final String progress;
  final bool done;
}

const songs = [
  Song(
    id: 1,
    title: '\uC65C\uACE1\uB41C \uB9AC\uB4EC',
    subtitle: '\uB9AC\uB4EC\uC73C\uB85C \uAE68\uC5B4\uB09C \uB098',
    thumbnailAsset: 'assets/sketch/song-thumb-1.png',
    bpm: 148,
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
    thumbnailAsset: 'assets/sketch/song-thumb-2.png',
    bpm: 132,
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
    thumbnailAsset: 'assets/sketch/song-thumb-3.png',
    bpm: 116,
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
    thumbnailAsset: 'assets/sketch/song-thumb-1.png',
    bpm: 172,
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
    thumbnailAsset: 'assets/sketch/song-thumb-2.png',
    bpm: 154,
    isLocked: true,
    difficulties: {
      Difficulty.easy: DifficultyInfo(level: 3, starRating: 2),
      Difficulty.normal: DifficultyInfo(level: 6, starRating: 3),
      Difficulty.hard: DifficultyInfo(level: 9, starRating: 4.5),
      Difficulty.extreme: DifficultyInfo(level: 12, starRating: 5),
    },
  ),
];
const wardrobe = [
  WearItem('기본 스크리블', 0, true),
  WearItem('헤어', 500, false),
  WearItem('장신구', 700, false),
  WearItem('상의', 900, false),
  WearItem('하의', 1200, false),
  WearItem('신발', 1500, false),
];

const quests = [
  Quest('곡 3회 플레이', '500', '2 / 3', false),
  Quest('GOOD 이하 없이 클리어', '50', '완료', true),
  Quest('콤보 50 달성', '700', '34 / 50', false),
  Quest('상점에서 아이템 구매', '900', '0 / 1', false),
];

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

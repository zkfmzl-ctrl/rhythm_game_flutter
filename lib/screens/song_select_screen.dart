part of '../main.dart';

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

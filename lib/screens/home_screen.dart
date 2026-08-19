part of '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onTab,
    required this.onStart,
    super.key,
  });
  final ValueChanged<AppTab> onTab;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) =>
      LandscapeHomeScreen(onTab: onTab, onStart: onStart);
}

class BestRecord {
  const BestRecord(this.song, this.difficulty, this.info);
  final Song song;
  final Difficulty difficulty;
  final DifficultyInfo info;
}

BestRecord? _findBestRecord() {
  BestRecord? best;
  for (final song in songs) {
    for (final entry in song.difficulties.entries) {
      final score = entry.value.bestScore;
      if (score == null) continue;
      if (best == null || score > best.info.bestScore!) {
        best = BestRecord(song, entry.key, entry.value);
      }
    }
  }
  return best;
}

class LandscapeHomeScreen extends StatelessWidget {
  const LandscapeHomeScreen({
    required this.onTab,
    required this.onStart,
    super.key,
  });
  final ValueChanged<AppTab> onTab;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final best = _findBestRecord();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 40,
          child: Stack(
            children: [
              // Character: bare Image, no PaperPanel/border/decoration of
              // any kind around it — just the transparent PNG standing on
              // the "floor" (bottom-aligned) of the shared global
              // background. Layer order: background (painted by
              // _AppBackdrop, further down in the tree) → character →
              // title/cards (added next, so they always paint in front).
              // BoxFit.contain inside a fixed-height box means it can
              // never be cropped, only ever rendered smaller.
              Positioned.fill(
                child: Align(
                  // shifted right of center (toward the buttons column) so
                  // the character reads as standing further into the
                  // hallway, closer to the background's vanishing point
                  alignment: const Alignment(0.7, 1.0),
                  child: FractionallySizedBox(
                    heightFactor: 0.5,
                    child: Image.asset(
                      'assets/sketch/home_character_transparent.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageTitle('왜곡된 리듬', subtitle: '리듬으로 깨어난 나'),
                  const Spacer(),
                  SizedBox(
                    width: 400,
                    child: AlertCard(onTap: () => onTab(AppTab.quest)),
                  ),
                  const SizedBox(height: 10),
                  if (best != null)
                    SizedBox(
                      width: 400,
                      child: BestRecordCard(
                          record: best, onTap: () => onTab(AppTab.music)),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 460,
                height: 92,
                child: _HomeBigButton(
                  icon: Icons.play_arrow,
                  title: '게임 시작',
                  subtitle: '리듬의 세계로 들어가기',
                  onTap: onStart,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 460,
                height: 92,
                child: _HomeBigButton(
                  icon: Icons.music_note,
                  title: '곡 선택',
                  subtitle: '곡을 선택하고 플레이',
                  onTap: () => onTab(AppTab.music),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeBigButton extends StatelessWidget {
  const _HomeBigButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

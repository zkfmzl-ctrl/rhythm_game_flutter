part of '../main.dart';

const _ringCenter = Offset(650, 320);
const _ringRadius = 185.0;
const _spawnRadius = 420.0;
const _hitTestRadius = 65.0;

Offset _ringPosition(int ring) {
  final offset = ringOffsets[ring]!;
  return _ringCenter + offset * _ringRadius;
}

Offset _spawnPosition(int ring) {
  final offset = ringOffsets[ring]!;
  return _ringCenter + offset * _spawnRadius;
}

class PlayScreen extends StatelessWidget {
  const PlayScreen({
    required this.game,
    required this.song,
    required this.difficulty,
    required this.onRing,
    required this.onReplay,
    required this.onExit,
    super.key,
  });

  final GameState game;
  final Song song;
  final Difficulty difficulty;
  final ValueChanged<int> onRing;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final rank = game.score == 0
        ? '-'
        : rankFrom(game.score, game.notes.length * 100);
    final knocked = game.elapsed < game.knockbackUntil;
    final hardMode =
        difficulty == Difficulty.hard || difficulty == Difficulty.extreme;
    final activeRings = hardMode ? _order8 : _order6;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: SizedBox(
              width: playStageWidth,
              height: playStageHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // background stays at the very bottom of the stack
                  // Positioned.fill forces this to the full 1300x600 canvas.
                  // Without it, a bare Image as a non-positioned Stack child
                  // sizes itself from its own intrinsic 1448x1086 (~1.33:1)
                  // ratio instead of the canvas's ~2.17:1 one, leaving a
                  // black gap down the right side once the canvas is wider
                  // than the image is tall.
                  const Positioned.fill(
                    child: Image(
                      image: AssetImage('assets/backgrounds/play2.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  // the character sits above the background but below the
                  // rings/notes, so it never hides what the player needs to see
                  Positioned(
                    left: _ringCenter.dx - 85,
                    top: _ringCenter.dy - 170,
                    width: 170,
                    height: 260,
                    child: _PlayCharacterLayer(knockedBack: knocked),
                  ),
                  RingBoardLayer(activeRings: activeRings),
                  MovingNotesLayer(game: game),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final ring = _ringFromPoint(
                            details.localPosition, activeRings);
                        if (ring != null) onRing(ring);
                      },
                    ),
                  ),
                  JudgementLayer(game: game),
                  Positioned(
                    left: 32,
                    top: playHudTop,
                    width: 420,
                    child: _SongHud(song: song, difficulty: difficulty),
                  ),
                  Positioned(
                    left: playStageWidth / 2 - 210,
                    top: playHudTop + 8,
                    width: 420,
                    child: _ProgressBar(game: game),
                  ),
                  Positioned(
                    right: 32,
                    top: playHudTop,
                    width: 260,
                    child: _ScoreHud(game: game, rank: rank, onExit: onExit),
                  ),
                  Positioned(
                    left: 32,
                    bottom: 26,
                    width: 220,
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

int? _ringFromPoint(Offset point, List<int> activeRings) {
  int? best;
  var bestDist = double.infinity;
  for (final ring in activeRings) {
    final dist = (_ringPosition(ring) - point).distance;
    if (dist < _hitTestRadius && dist < bestDist) {
      best = ring;
      bestDist = dist;
    }
  }
  return best;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.game});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    final progress =
        (game.elapsed / math.max(game.durationMs, 1)).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 22,
          child: CustomPaint(painter: _ProgressPainter(progress: progress)),
        ),
        Text(
          '${formatClock(game.elapsed)} / ${formatClock(game.durationMs)}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

/// The 8 static judgement rings the character stands in the middle of. Each
/// ring shows its concentric PERFECT/GREAT/GOOD bands ("핀 포인트" targets)
/// so the player always knows where to tap, no matter what's approaching.
class RingBoardLayer extends StatelessWidget {
  const RingBoardLayer({required this.activeRings, super.key});
  final List<int> activeRings;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: activeRings.map((ring) {
        final pos = _ringPosition(ring);
        final kind = ring == 4 || ring == 5
            ? NoteKind.hand
            : ring == 8
                ? NoteKind.floor
                : NoteKind.aerial;
        return Positioned(
          left: pos.dx - 44,
          top: pos.dy - 44,
          width: 88,
          height: 88,
          child: CustomPaint(painter: _RingPainter(kind: kind)),
        );
      }).toList(),
    );
  }
}

Color _kindColor(NoteKind kind) {
  switch (kind) {
    case NoteKind.aerial:
      return const Color(0xffe05a4e);
    case NoteKind.hand:
      return const Color(0xff9a5ce0);
    case NoteKind.floor:
      return const Color(0xff4fa3e0);
    case NoteKind.long:
      return const Color(0xffe0c04f);
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.kind});
  final NoteKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final color = _kindColor(kind);
    for (final r in [size.width / 2, size.width / 3, size.width / 6]) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 0.55),
      );
    }
    canvas.drawCircle(center, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.kind != kind;
}

class MovingNotesLayer extends StatelessWidget {
  const MovingNotesLayer({required this.game, super.key});
  final GameState game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: game.notes.where((note) => !note.judged).map((note) {
        final p = ((game.elapsed - (note.hitAt - 1350)) / 1350).clamp(
          -0.3,
          1.15,
        );
        if (p < -0.2 || p > 1.1) {
          return SizedBox.shrink(key: ValueKey(note.id));
        }
        final spawn = _spawnPosition(note.ring);
        final target = _ringPosition(note.ring);
        final point = Offset.lerp(spawn, target, p.clamp(0.0, 1.0))!;
        final scale = 0.45 + p * 0.85;
        return Positioned(
          key: ValueKey(note.id),
          left: point.dx - 26 * scale,
          top: point.dy - 26 * scale,
          child: _PlayNoteShape(kind: note.kind, scale: scale),
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
    // pinned to the top, below the progress bar and between the song-info
    // and score HUD panels, so it never sits on top of the ring board /
    // character it used to cover.
    return Positioned(
      left: _ringCenter.dx - 200,
      top: playHudTop + 62,
      width: 400,
      child: IgnorePointer(
        child: Column(
          children: [
            Text(
              judgeText(game.lastJudge),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                height: 0.95,
                color: Colors.white.withValues(alpha: 0.9),
                shadows: const [Shadow(color: Colors.black, blurRadius: 0)],
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${game.combo} COMBO',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.85),
                shadows: const [Shadow(color: Colors.black, blurRadius: 0)],
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
  const _PlayCharacterLayer({required this.knockedBack});
  final bool knockedBack;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 120),
      offset: knockedBack ? const Offset(-0.12, 0) : Offset.zero,
      child: ColorFiltered(
        colorFilter: knockedBack
            ? const ColorFilter.mode(Color(0x669a5ce0), BlendMode.srcATop)
            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: Image.asset(
          'assets/sketch/home_character_transparent.png',
          fit: BoxFit.contain,
          alignment: Alignment.bottomCenter,
        ),
      ),
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
              width: 64, height: 64, fit: BoxFit.cover),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _DarkTag(diffText(difficulty)),
                    const SizedBox(width: 10),
                    Text(
                      'BPM  ${song.bpm}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800),
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
                          fontSize: 34,
                          height: 0.95,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${game.combo}',
                      style: const TextStyle(
                          fontSize: 36,
                          height: 0.9,
                          fontWeight: FontWeight.w900)),
                  Text(
                    'COMBO',
                    style: TextStyle(
                      fontSize: 15,
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
                padding: const EdgeInsets.all(11),
                child: Icon(
                  Icons.pause,
                  size: 34,
                  color: Colors.black.withValues(alpha: 0.92),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PaperPanel(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('현재 등급',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              Center(
                child: Text(rank,
                    style: const TextStyle(
                        fontSize: 50, fontWeight: FontWeight.w900)),
              ),
              _RankGauge(
                percent: game.notes.isEmpty
                    ? 0
                    : (game.score / (game.notes.length * 100)).clamp(0.0, 1.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              symbol,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
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
      height: 24,
      width: double.infinity,
      child: CustomPaint(painter: _RankGaugePainter(percent: percent)),
    );
  }
}

class _PlayNoteShape extends StatelessWidget {
  const _PlayNoteShape({
    required this.kind,
    required this.scale,
  });
  final NoteKind kind;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = Size(52 * scale, 52 * scale);
    return CustomPaint(
      size: size,
      painter: _NoteShapePainter(kind: kind),
    );
  }
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
      Rect.fromLTWH(0, y - 5, size.width, 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black,
    );
    canvas.drawRect(
      Rect.fromLTWH(1, y - 4, (size.width - 2) * percent, 8),
      Paint()..color = Colors.black.withValues(alpha: 0.88),
    );
  }

  @override
  bool shouldRepaint(covariant _RankGaugePainter oldDelegate) =>
      oldDelegate.percent != percent;
}

class _NoteShapePainter extends CustomPainter {
  const _NoteShapePainter({required this.kind});
  final NoteKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final color = _kindColor(kind);
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;

    // a dark halo behind everything so the bright fill/stroke pops against
    // any part of the busy sketch background
    canvas.drawCircle(center, size.width / 2, Paint()..color = Colors.black);

    switch (kind) {
      case NoteKind.aerial:
        final hex = Path();
        for (var i = 0; i < 6; i++) {
          final a = math.pi / 3 * i - math.pi / 2;
          final pt = center + Offset(math.cos(a), math.sin(a)) * r;
          i == 0 ? hex.moveTo(pt.dx, pt.dy) : hex.lineTo(pt.dx, pt.dy);
        }
        hex.close();
        canvas.drawPath(hex, fill);
        canvas.drawPath(hex, stroke);
      case NoteKind.hand:
        canvas.drawCircle(center, r, fill);
        canvas.drawCircle(center, r, stroke);
        final iconPaint = Paint()
          ..color = const Color(0xffeee9dc)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(center + const Offset(-6, -4),
            center + const Offset(-6, 6), iconPaint);
        canvas.drawLine(center + const Offset(0, -6),
            center + const Offset(0, 6), iconPaint);
        canvas.drawLine(
            center + const Offset(6, -4), center + const Offset(6, 6), iconPaint);
      case NoteKind.floor:
        canvas.drawCircle(center, r, fill);
        canvas.drawCircle(center, r, stroke);
      case NoteKind.long:
        canvas.drawCircle(center, r, fill);
        canvas.drawCircle(center, r, stroke);
        canvas.drawCircle(center, r * 0.55, stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _NoteShapePainter oldDelegate) =>
      oldDelegate.kind != kind;
}

part of '../main.dart';

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
          FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: SizedBox(
              width: playStageWidth,
              height: playStageHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.asset('assets/backgrounds/play2.png',
                      fit: BoxFit.cover),
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        final lane = _laneFromPoint(
                          details.localPosition,
                          const Size(playStageWidth, playStageHeight),
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
    const stageSize = Size(playStageWidth, playStageHeight);
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

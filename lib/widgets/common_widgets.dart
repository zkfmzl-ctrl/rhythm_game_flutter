part of '../main.dart';

class ContainFrame extends StatelessWidget {
  const ContainFrame({required this.child, super.key});

  // The phone's landscape viewport is approximately 780x360 logical pixels.
  // Match the phone's approximately 2.17:1 landscape viewport while keeping
  // enough vertical room for the settings/quest content. This avoids the
  // severe 0.31x scale caused by the old 1280x720 canvas.
  static const designWidth = 1300.0;
  static const designHeight = 600.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: SizedBox(
          width: designWidth,
          height: designHeight,
          child: child,
        ),
      ),
    );
  }
}

// Purely decorative: the tunnel photo, paper tint and scratch texture used
// behind every non-play screen. Sized to whatever box it's given by its
// parent (see main.dart, where that's the real physical screen, not the
// safe-area-inset one, so it reaches every edge on devices with a
// cutout/curved edge in landscape).
class _AppBackdrop extends StatelessWidget {
  const _AppBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xffd3d0c5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xffc5c2b8), Color(0xffece9de), Color(0xffbbb8af)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // stretched wider than a plain BoxFit.cover would leave it, so
          // the tunnel reads as more panoramic instead of narrow/zoomed
          ClipRect(
            child: Transform.scale(
              scaleX: 1.25,
              child: Image.asset('assets/backgrounds/main.png',
                  fit: BoxFit.cover),
            ),
          ),
          CustomPaint(painter: PaperScratchPainter()),
        ],
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

class AlertCard extends StatelessWidget {
  const AlertCard({this.onTap, super.key});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('알림', style: TextStyle(fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text('새로운 곡과 임무를 확인하세요.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}

class BestRecordCard extends StatelessWidget {
  const BestRecordCard({required this.record, this.onTap, super.key});
  final BestRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('최고 기록',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              const Text('전체 랭킹',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              const Icon(Icons.chevron_right, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.asset(record.song.thumbnailAsset,
                    width: 44, height: 44, fit: BoxFit.cover),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(record.song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w900)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            border: Border.all(width: 1.5),
                            color: const Color(0xffeeeade),
                          ),
                          child: Text(diffText(record.difficulty),
                              style: const TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 6),
                        Text(formatScore(record.info.bestScore!),
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              Text(record.info.bestRank ?? '-',
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }
}

class PaperToggle extends StatelessWidget {
  const PaperToggle({required this.value, required this.onChanged, super.key});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(width: 2),
          color: value ? Colors.black : const Color(0xffeeeade),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(width: 2),
              color: value ? const Color(0xffeeeade) : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class CurrencyBar extends StatelessWidget {
  const CurrencyBar(
      {required this.coins, required this.gems, this.onTap, super.key});
  final int coins;
  final int gems;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      onTap: onTap,
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

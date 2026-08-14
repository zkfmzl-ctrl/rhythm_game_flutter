part of '../main.dart';

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

part of '../main.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final characters = [
      const _CharacterCardData(
        name: '루아',
        status: '선택 중',
        locked: false,
        hp: 80,
        rhythm: 70,
        speed: 60,
        focus: 50,
      ),
      const _CharacterCardData(
        name: '리마',
        status: '잠김',
        locked: true,
        hp: 88,
        rhythm: 80,
        speed: 66,
        focus: 58,
      ),
      const _CharacterCardData(
        name: '아이',
        status: '잠김',
        locked: true,
        hp: 96,
        rhythm: 90,
        speed: 72,
        focus: 66,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('캐릭터', subtitle: '리듬 공명'),
        Expanded(
          child: ListView.builder(
            itemCount: characters.length,
            itemBuilder: (context, index) {
              final character = characters[index];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == characters.length - 1 ? 0 : 12),
                child: PaperPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Opacity(
                        opacity: character.locked ? 0.45 : 1,
                        child: Image.asset(
                          'assets/character/character_01.png',
                          width: 76,
                          height: 106,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              character.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            Text(character.status,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(
                              '체력 ${character.hp} / 리듬 감응력 ${character.rhythm}\n'
                              '이동 속도 ${character.speed} / 집중력 ${character.focus}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '고유 능력: 리듬 공명',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      if (character.locked) const Icon(Icons.lock),
                    ],
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

class _CharacterCardData {
  const _CharacterCardData({
    required this.name,
    required this.status,
    required this.locked,
    required this.hp,
    required this.rhythm,
    required this.speed,
    required this.focus,
  });

  final String name;
  final String status;
  final bool locked;
  final int hp;
  final int rhythm;
  final int speed;
  final int focus;
}

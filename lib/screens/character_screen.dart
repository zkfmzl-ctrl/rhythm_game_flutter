part of '../main.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  int _selected = 0;

  static const _characters = [
    _CharacterCardData(
      name: '나',
      description: '왜곡된 리듬 속에서 깨어난 소년.\n아직 정체를 기억하지 못한다.',
      locked: false,
      progress: 1,
      hp: 80,
      rhythm: 70,
      speed: 60,
      focus: 50,
      ability: '리듬 공명',
      abilityDesc: '완벽한 타이밍 입력 시\n짧은 시간 동안 리듬 감응력 증가',
    ),
    _CharacterCardData(
      name: '엄마',
      description: '리듬의 기억을 간직한 존재.',
      locked: true,
      progress: 0.25,
      hp: 88,
      rhythm: 80,
      speed: 66,
      focus: 58,
      ability: '기억의 잔향',
      abilityDesc: '특정 조건을 달성하면 해금됩니다.',
    ),
    _CharacterCardData(
      name: '아빠',
      description: '어딘가에서 나를 기다리고 있다.',
      locked: true,
      progress: 0.10,
      hp: 96,
      rhythm: 90,
      speed: 72,
      focus: 66,
      ability: '???',
      abilityDesc: '특정 조건을 달성하면 해금됩니다.',
    ),
    _CharacterCardData(
      name: '아이',
      description: '잃어버린 순수한 리듬.',
      locked: true,
      progress: 0,
      hp: 70,
      rhythm: 95,
      speed: 80,
      focus: 74,
      ability: '???',
      abilityDesc: '특정 조건을 달성하면 해금됩니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _characters[_selected];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 42,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageTitle('캐릭터', subtitle: '리듬 공명'),
              Expanded(
                child: PaperPanel(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Image.asset(
                          'assets/sketch/home_character_transparent.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(current.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.w900)),
                          ),
                          if (!current.locked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration:
                                  BoxDecoration(border: Border.all(width: 1.5)),
                              child: const Text('선택 중',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(current.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      _StatBar('체력', current.hp),
                      _StatBar('리듬 감응력', current.rhythm),
                      _StatBar('이동 속도', current.speed),
                      _StatBar('집중력', current.focus),
                      const SizedBox(height: 10),
                      const Text('고유 능력',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      PaperPanel(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.blur_circular, size: 26),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(current.ability,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900)),
                                  Text(current.abilityDesc,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 58,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // matches PageTitle's rendered height so this list starts at
              // exactly the same y as the character info panel on the left
              // (also clears the CurrencyBar overlay pinned top-right,
              // which sits outside this scaled content area).
              const SizedBox(height: 78),
              // the currently-equipped character gets its own card sized to
              // match the left info panel's height exactly; the rest of the
              // roster sits in a smaller scrollable strip below it.
              Expanded(
                flex: 5,
                child: _RosterCard(
                  character: _characters[0],
                  selected: _selected == 0,
                  hero: true,
                  onTap: _characters[0].locked
                      ? null
                      : () => setState(() => _selected = 0),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                flex: 4,
                child: ListView.builder(
                  itemCount: _characters.length - 1,
                  itemBuilder: (context, i) {
                    final index = i + 1;
                    final character = _characters[index];
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: index == _characters.length - 1 ? 0 : 10),
                      child: _RosterCard(
                        character: character,
                        selected: _selected == index,
                        hero: false,
                        onTap: character.locked
                            ? null
                            : () => setState(() => _selected = index),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RosterCard extends StatelessWidget {
  const _RosterCard({
    required this.character,
    required this.selected,
    required this.hero,
    required this.onTap,
  });

  final _CharacterCardData character;
  final bool selected;
  final bool hero;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PaperPanel(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Opacity(
              opacity: character.locked ? 0.45 : 1,
              child: SizedBox(
                width: hero ? 104 : 58,
                height: hero ? 150 : 84,
                child: Image.asset(
                  'assets/sketch/home_character_transparent.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          character.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: hero ? 26 : 20,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (character.locked)
                        const Icon(Icons.lock, size: 20)
                      else if (selected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration:
                              BoxDecoration(border: Border.all(width: 1.5)),
                          child: const Text('선택 중',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                    ],
                  ),
                  Text(character.description,
                      maxLines: hero ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _ProgressRow(character.progress),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow(this.progress);
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('진행도',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              border: Border.all(width: 1.5),
              color: const Color(0xffeeeade),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0, 1),
              child: Container(color: Colors.black),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(progress >= 1 ? '-' : '${(progress * 100).round()}%',
              textAlign: TextAlign.right,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                border: Border.all(width: 1.5),
                color: const Color(0xffeeeade),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (value / 100).clamp(0, 1),
                child: Container(color: Colors.black),
              ),
            ),
          ),
          SizedBox(
            width: 26,
            child: Text(value.toString(),
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _CharacterCardData {
  const _CharacterCardData({
    required this.name,
    required this.description,
    required this.locked,
    required this.progress,
    required this.hp,
    required this.rhythm,
    required this.speed,
    required this.focus,
    required this.ability,
    required this.abilityDesc,
  });

  final String name;
  final String description;
  final bool locked;
  final double progress;
  final int hp;
  final int rhythm;
  final int speed;
  final int focus;
  final String ability;
  final String abilityDesc;
}

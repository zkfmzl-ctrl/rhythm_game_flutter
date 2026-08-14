part of '../main.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle('퀘스트', subtitle: '데일리'),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuestFilter('데일리'),
              _QuestFilter('위클리'),
              _QuestFilter('업적'),
              _QuestFilter('모두 받기'),
            ],
          ),
          const SizedBox(height: 12),
          ...quests.map(
            (quest) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PaperPanel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(quest.done ? Icons.check_circle : Icons.star,
                        size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${quest.title}\n${quest.progress}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: quest.done ? () {} : null,
                      child: Text(quest.done ? '보상 받기' : '바로 가기'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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

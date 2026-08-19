part of '../main.dart';

class QuestScreen extends StatefulWidget {
  const QuestScreen({
    required this.claimedIds,
    required this.onClaim,
    required this.onGoTo,
    super.key,
  });

  final Set<int> claimedIds;
  final ValueChanged<Quest> onClaim;
  final ValueChanged<Quest> onGoTo;

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  static const _categories = ['데일리', '위클리', '업적'];
  String _category = '데일리';

  @override
  Widget build(BuildContext context) {
    final visible = quests.where((q) => q.category == _category).toList();
    final claimable = quests
        .where((q) => q.done && !widget.claimedIds.contains(q.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle('퀘스트', subtitle: _category),
        Row(
          children: _categories
              .map((label) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _QuestFilter(
                        label,
                        selected: _category == label,
                        onTap: () => setState(() => _category = label),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: visible.map((quest) {
              final claimed = widget.claimedIds.contains(quest.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PaperPanel(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                          claimed
                              ? Icons.check_circle
                              : quest.done
                                  ? Icons.redeem
                                  : Icons.star,
                          size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${quest.title}\n${quest.progress} · 보상 ${quest.reward}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: claimed
                            ? null
                            : quest.done
                                ? () => widget.onClaim(quest)
                                : () => widget.onGoTo(quest),
                        child: Text(claimed
                            ? '수령 완료'
                            : quest.done
                                ? '보상 받기'
                                : '바로 가기'),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: claimable.isEmpty
                ? null
                : () {
                    for (final quest in claimable) {
                      widget.onClaim(quest);
                    }
                  },
            child: Text('모두 받기 (${claimable.length})'),
          ),
        ),
      ],
    );
  }
}

class _QuestFilter extends StatelessWidget {
  const _QuestFilter(this.label, {required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(label,
            style: TextStyle(
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                decoration: selected ? TextDecoration.underline : null)),
      ),
    );
  }
}

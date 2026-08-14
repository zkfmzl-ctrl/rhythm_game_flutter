part of '../main.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({
    required this.coins,
    required this.gems,
    required this.onBuy,
    super.key,
  });
  final int coins;
  final int gems;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    const packs = ['추천', '장비/효과', '묶음 상품', '재화', '꾸미기'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageTitle('상점', subtitle: '추천'),
        PaperPanel(
          child: Column(
            children: [
              Image.asset('assets/sketch/shop-grid.png',
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter),
              Text('재화: $coins / $gems',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: packs
              .asMap()
              .entries
              .map((entry) => SizedBox(
                    width: 120,
                    child: PaperPanel(
                      onTap: onBuy,
                      child: Column(
                        children: [
                          Image.asset('assets/sketch/song-thumb-1.png',
                              width: 50, height: 42, fit: BoxFit.cover),
                          Text(entry.value,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900)),
                          Text(entry.key.isEven
                              ? '${(entry.key + 1) * 300}'
                              : '${(entry.key + 1) * 200}'),
                          ElevatedButton(
                              onPressed: onBuy, child: const Text('구매')),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

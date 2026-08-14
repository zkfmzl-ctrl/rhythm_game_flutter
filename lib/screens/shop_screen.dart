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
    const categories = ['추천', '장비/효과', '묶음 상품', '재화', '꾸미기'];
    const products = [
      _ShopProduct('왜곡의 심장', '추천', '900', 'assets/items/jin/jin.png'),
      _ShopProduct('리듬 증폭기', '장비/효과', '700', 'assets/items/efect/efect.png'),
      _ShopProduct('잔상 이펙트', '장비/효과', '400', 'assets/items/efect/efect.png'),
      _ShopProduct('펄스 헤어', '꾸미기', '300', 'assets/items/hair/hair.png'),
      _ShopProduct('터널 슈즈', '꾸미기', '500', 'assets/items/shoe/shoe.png'),
      _ShopProduct('집중 부스터 팩', '묶음 상품', '600', 'assets/items/hand/hand.png'),
      _ShopProduct('보석 묶음', '재화', '200', 'assets/items/jin/jin.png'),
      _ShopProduct('스크래치 의상', '꾸미기', '800', 'assets/items/cloth/cloth.png'),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 34,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageTitle('상점', subtitle: '추천'),
                _CurrencyChip(icon: Icons.toll, label: coins.toString()),
                const SizedBox(height: 8),
                _CurrencyChip(icon: Icons.diamond, label: gems.toString()),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories
                      .map((label) => PaperPanel(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            child: Text(label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 66,
          child: GridView.builder(
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 128,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final item = products[index];
              return PaperPanel(
                onTap: onBuy,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xfffffbef),
                            border: Border.all(width: 1.5),
                          ),
                          child: Image.asset(item.asset, fit: BoxFit.contain),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.price,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        SizedBox(
                          height: 30,
                          child: ElevatedButton(
                            onPressed: onBuy,
                            child: const Text('구매'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShopProduct {
  const _ShopProduct(this.name, this.category, this.price, this.asset);

  final String name;
  final String category;
  final String price;
  final String asset;
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const MiniBox('+'),
        ],
      ),
    );
  }
}

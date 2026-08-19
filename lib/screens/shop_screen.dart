part of '../main.dart';

class ShopScreen extends StatefulWidget {
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
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _categories = ['추천', '장비/효과', '묶음 상품', '재화', '꾸미기'];
  static const _products = [
    _ShopProduct('왜곡의 심장', '장비/효과', '900', 'assets/items/jin/jin.png'),
    _ShopProduct('리듬 증폭기', '장비/효과', '700', 'assets/items/efect/efect.png'),
    _ShopProduct('잔상 이펙트', '장비/효과', '400', 'assets/items/efect/efect.png'),
    _ShopProduct('펄스 헤어', '꾸미기', '300', 'assets/items/hair/hair.png'),
    _ShopProduct('터널 슈즈', '꾸미기', '500', 'assets/items/shoe/shoe.png'),
    _ShopProduct('집중 부스터 팩', '묶음 상품', '600', 'assets/items/hand/hand.png'),
    _ShopProduct('보석 묶음', '재화', '200', 'assets/items/jin/jin.png'),
    _ShopProduct('스크래치 의상', '꾸미기', '800', 'assets/items/cloth/cloth.png'),
  ];

  String _selected = '추천';

  @override
  Widget build(BuildContext context) {
    final products = _selected == '추천'
        ? _products
        : _products.where((p) => p.category == _selected).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle('상점', subtitle: _selected),
        Row(
          children: _categories
              .map((label) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PaperPanel(
                        onTap: () => setState(() => _selected = label),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: Text(label,
                              style: TextStyle(
                                  fontWeight: _selected == label
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  decoration: _selected == label
                                      ? TextDecoration.underline
                                      : null)),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 120,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final item = products[index];
              return PaperPanel(
                onTap: widget.onBuy,
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
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
                            onPressed: widget.onBuy,
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

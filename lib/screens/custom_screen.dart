part of '../main.dart';

class CustomScreen extends StatelessWidget {
  const CustomScreen({
    required this.gems,
    required this.selectedWear,
    required this.onEquip,
    super.key,
  });

  final int gems;
  final String selectedWear;
  final ValueChanged<WearItem> onEquip;

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageTitle('꾸미기', subtitle: '착용 중 아이템'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 42,
                child: PaperPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/character/character_01.png',
                              width: 82, height: 130, fit: BoxFit.contain),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '헤어: $selectedWear\n장신구: 기본 장신구\n상의: 기본 상의\n하의: 기본 하의\n신발: 기본 신발\n얼굴: 기본 얼굴',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('착용 중 아이템',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 58,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: wardrobe
                      .map((item) => SizedBox(
                            width: 112,
                            height: 116,
                            child: PaperPanel(
                              onTap: () =>
                                  item.price <= gems ? onEquip(item) : null,
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Image.asset(item.asset,
                                      width: 34,
                                      height: 34,
                                      fit: BoxFit.contain),
                                  const SizedBox(height: 5),
                                  Text(item.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900)),
                                  const Spacer(),
                                  Text(selectedWear == item.name
                                      ? '장착 해제'
                                      : item.owned
                                          ? '장착하기'
                                          : '${item.price}'),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      );
  }
}

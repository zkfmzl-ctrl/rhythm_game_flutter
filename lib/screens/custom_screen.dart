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
              flex: 43,
              child: PaperPanel(
                child: Column(
                  children: [
                    Image.asset('assets/sketch/wardrobe-preview.png',
                        height: 270, fit: BoxFit.cover),
                    const SizedBox(height: 8),
                    const Text('착용 중 아이템',
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    Text(
                        '헤어: $selectedWear\n장신구: 기본 장신구\n상의: 기본 상의\n하의: 기본 하의\n신발: 기본 신발\n얼굴: 기본 얼굴'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 57,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: wardrobe
                    .map((item) => SizedBox(
                          width: 108,
                          child: PaperPanel(
                            onTap: () =>
                                item.price <= gems ? onEquip(item) : null,
                            child: Column(
                              children: [
                                Image.asset('assets/sketch/song-thumb-2.png',
                                    width: 46, height: 38, fit: BoxFit.cover),
                                Text(item.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900)),
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

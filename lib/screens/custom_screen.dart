part of '../main.dart';

class CustomScreen extends StatefulWidget {
  const CustomScreen({
    required this.gems,
    required this.equipped,
    required this.onEquip,
    super.key,
  });

  final int gems;
  final Map<String, String> equipped;
  final ValueChanged<WearItem> onEquip;

  @override
  State<CustomScreen> createState() => _CustomScreenState();
}

class _CustomScreenState extends State<CustomScreen> {
  String _slot = '헤어';

  String? _assetFor(String slot, String? name) {
    if (name == null) return null;
    for (final item in wardrobe) {
      if (item.slot == slot && item.name == name) return item.asset;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final items = wardrobe.where((item) => item.slot == _slot).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // left: character portrait + a vertical strip of the 6 equip slots,
        // each showing the icon of whatever is currently equipped there.
        Expanded(
          flex: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PaperPanel(
                  padding: EdgeInsets.zero,
                  child: ClipRect(
                    child: Image.asset(
                      'assets/sketch/home_character_transparent.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 92,
                child: Column(
                  children: wardrobeSlots.map((slot) {
                    final asset = _assetFor(slot, widget.equipped[slot]);
                    final selected = slot == _slot;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: slot == wardrobeSlots.last ? 0 : 8),
                        child: PaperPanel(
                          onTap: () => setState(() => _slot = slot),
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: asset != null
                                    ? Image.asset(asset, fit: BoxFit.contain)
                                    : const Icon(Icons.close, size: 18),
                              ),
                              Text(slot,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: selected
                                          ? FontWeight.w900
                                          : FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // right: category tabs + the item grid for the selected slot.
        Expanded(
          flex: 58,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // clears the CurrencyBar overlay pinned at the top-right of
              // the screen, which sits outside this scaled content area.
              const SizedBox(height: 46),
              Row(
                children: wardrobeSlots
                    .map((slot) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: PaperPanel(
                              onTap: () => setState(() => _slot = slot),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Center(
                                child: Text(slot,
                                    style: TextStyle(
                                        fontWeight: _slot == slot
                                            ? FontWeight.w900
                                            : FontWeight.w700,
                                        decoration: _slot == slot
                                            ? TextDecoration.underline
                                            : null)),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisExtent: 120,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final equippedHere =
                        widget.equipped[item.slot] == item.name;
                    return _WearTile(
                      item: item,
                      equipped: equippedHere,
                      affordable: item.price <= widget.gems,
                      onTap: item.unlockCondition != null
                          ? null
                          : () => widget.onEquip(item),
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

class _WearTile extends StatelessWidget {
  const _WearTile({
    required this.item,
    required this.equipped,
    required this.affordable,
    required this.onTap,
  });

  final WearItem item;
  final bool equipped;
  final bool affordable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = item.unlockCondition != null;
    return PaperPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          if (locked)
            const Expanded(child: Icon(Icons.lock, size: 26))
          else
            Expanded(
              child: Image.asset(item.asset, fit: BoxFit.contain),
            ),
          const SizedBox(height: 5),
          Text(
            locked ? '??????' : item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            locked
                ? item.unlockCondition!
                : equipped
                    ? '착용 중'
                    : item.owned
                        ? '보유 중'
                        : affordable
                            ? '${item.price}'
                            : '${item.price} (부족)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

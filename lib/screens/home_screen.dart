part of '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onTab, required this.onStart, super.key});
  final ValueChanged<AppTab> onTab;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) =>
      LandscapeHomeScreen(onTab: onTab, onStart: onStart);
}

class _HomeAction {
  const _HomeAction(this.title, this.subtitle, this.icon, this.onTap);

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class LandscapeHomeScreen extends StatelessWidget {
  const LandscapeHomeScreen(
      {required this.onTab, required this.onStart, super.key});
  final ValueChanged<AppTab> onTab;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _HomeAction('게임 시작', '리듬의 세계로 들어가기', Icons.play_arrow, onStart),
      _HomeAction(
          '곡 선택', '곡을 선택하고 플레이', Icons.music_note, () => onTab(AppTab.music)),
      _HomeAction('캐릭터', '캐릭터 확인 및 변경', Icons.person_pin,
          () => onTab(AppTab.character)),
      _HomeAction(
          '꾸미기', '의상과 이펙트 변경', Icons.checkroom, () => onTab(AppTab.custom)),
      _HomeAction(
          '퀘스트', '임무를 완료하고 보상 받기', Icons.fact_check, () => onTab(AppTab.quest)),
      _HomeAction(
          '상점', '아이템과 패키지 구매', Icons.shopping_cart, () => onTab(AppTab.shop)),
      _HomeAction(
          '설정', '게임 환경 설정', Icons.settings, () => onTab(AppTab.settings)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 42,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageTitle('왜곡된 리듬', subtitle: '리듬으로 깨어난 나'),
                  Expanded(
                    child: PaperPanel(
                      padding: EdgeInsets.zero,
                      child: ClipRect(
                        child: Image.asset(
                          'assets/sketch/home-character.png',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const PaperPanel(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('공지\n새로운 곡과 임무를 확인하세요.',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 58,
              child: GridView.builder(
                itemCount: actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 92,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) =>
                    _LandscapeActionButton(item: actions[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LandscapeActionButton extends StatelessWidget {
  const _LandscapeActionButton({required this.item});
  final _HomeAction item;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      onTap: item.onTap,
      child: Row(
        children: [
          Icon(item.icon, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900)),
                Text(item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

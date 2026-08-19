part of '../main.dart';

class WearItem {
  const WearItem(
    this.name,
    this.slot,
    this.price,
    this.owned,
    this.asset, {
    this.unlockCondition,
  });
  final String name;
  final String slot;
  final int price;
  final bool owned;
  final String asset;
  final String? unlockCondition;
}

class Quest {
  const Quest(
      this.id, this.category, this.title, this.reward, this.progress,
      {required this.done});
  final int id;
  final String category;
  final String title;
  final int reward;
  final String progress;
  final bool done;
}

const wardrobeSlots = ['헤어', '장신구', '상의', '하의', '신발', '얼굴'];

const wardrobe = [
  // 헤어
  WearItem('혼돈의 스크리블', '헤어', 0, true, 'assets/items/hair/hair.png'),
  WearItem('날카로운 파동', '헤어', 0, true, 'assets/items/hair/hair.png'),
  WearItem('어둠의 실타래', '헤어', 0, true, 'assets/items/hair/hair.png'),
  WearItem('잿더미 헤어', '헤어', 1200, false, 'assets/items/hair/hair.png'),
  WearItem('정전기 소용돌이', '헤어', 1500, false, 'assets/items/hair/hair.png'),
  WearItem('뒤섞인 리본', '헤어', 1800, false, 'assets/items/hair/hair.png'),
  WearItem('왜곡된 중절모', '헤어', 2000, false, 'assets/items/hair/hair.png'),
  WearItem('???', '헤어', 0, false, 'assets/items/hair/hair.png',
      unlockCondition: '최고 기록 HARD 달성'),
  // 장신구 (손 아이템 그림을 장신구로 재사용)
  WearItem('랜턴', '장신구', 0, true, 'assets/items/hand/hand_01.png'),
  WearItem('인형', '장신구', 600, false, 'assets/items/hand/hand_02.png'),
  WearItem('손거울', '장신구', 700, false, 'assets/items/hand/hand_03.png'),
  WearItem('장미', '장신구', 800, false, 'assets/items/hand/hand_04.png'),
  WearItem('약병', '장신구', 900, false, 'assets/items/hand/hand_05.png'),
  WearItem('두루마리', '장신구', 1000, false, 'assets/items/hand/hand_06.png'),
  WearItem('나침반', '장신구', 1100, false, 'assets/items/hand/hand_07.png'),
  // 상의
  WearItem('그림자 후드', '상의', 0, true, 'assets/items/cloth/top_01.png'),
  WearItem('다크 케이프', '상의', 800, false, 'assets/items/cloth/top_02.png'),
  WearItem('비대칭 랩탑', '상의', 900, false, 'assets/items/cloth/top_03.png'),
  WearItem('오버사이즈 니트', '상의', 1000, false, 'assets/items/cloth/top_04.png'),
  WearItem('터틀넥 니트', '상의', 1000, false, 'assets/items/cloth/top_05.png'),
  WearItem('레더 자켓', '상의', 1300, false, 'assets/items/cloth/top_06.png'),
  WearItem('롱 트렌치코트', '상의', 1500, false, 'assets/items/cloth/top_07.png'),
  // 하의
  WearItem('일자 팬츠', '하의', 0, true, 'assets/items/cloth/bottom_01.png'),
  WearItem('슬림 팬츠', '하의', 700, false, 'assets/items/cloth/bottom_05.png'),
  WearItem('와이드 팬츠', '하의', 750, false, 'assets/items/cloth/bottom_06.png'),
  WearItem('하프 팬츠', '하의', 650, false, 'assets/items/cloth/bottom_07.png'),
  WearItem('드레이프 하의', '하의', 900, false, 'assets/items/cloth/bottom_02.png'),
  WearItem('슬릿 스커트', '하의', 950, false, 'assets/items/cloth/bottom_03.png'),
  WearItem('오버롤 하의', '하의', 1100, false, 'assets/items/cloth/bottom_04.png'),
  // 신발
  WearItem('플랫 슈즈', '신발', 0, true, 'assets/items/shoe/shoe_01.png'),
  WearItem('버클 슈즈', '신발', 500, false, 'assets/items/shoe/shoe_02.png'),
  WearItem('청키 슈즈', '신발', 650, false, 'assets/items/shoe/shoe_03.png'),
  WearItem('플랫폼 슈즈', '신발', 700, false, 'assets/items/shoe/shoe_04.png'),
  WearItem('웨지 슈즈', '신발', 650, false, 'assets/items/shoe/shoe_05.png'),
  WearItem('컴뱃 부츠', '신발', 900, false, 'assets/items/shoe/shoe_06.png'),
  WearItem('워커 부츠', '신발', 950, false, 'assets/items/shoe/shoe_07.png'),
  // 얼굴
  WearItem('없음', '얼굴', 0, true, 'assets/items/jin/jin.png'),
  WearItem('금 간 가면', '얼굴', 1600, false, 'assets/items/jin/jin.png'),
  WearItem('???', '얼굴', 0, false, 'assets/items/jin/jin.png',
      unlockCondition: '다이아 5,000개 보유'),
];

const quests = [
  Quest(1, '데일리', '곡 3회 플레이', 500, '2 / 3', done: false),
  Quest(2, '데일리', 'GOOD 이하 없이 클리어', 50, '완료', done: true),
  Quest(3, '위클리', '콤보 50 달성', 700, '34 / 50', done: false),
  Quest(4, '위클리', '상점에서 아이템 구매', 900, '0 / 1', done: false),
  Quest(5, '업적', '곡 30회 클리어', 2000, '0 / 30', done: false),
];

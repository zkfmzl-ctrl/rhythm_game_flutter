part of '../main.dart';

class WearItem {
  const WearItem(this.name, this.price, this.owned);
  final String name;
  final int price;
  final bool owned;
}

class Quest {
  const Quest(this.title, this.reward, this.progress, this.done);
  final String title;
  final String reward;
  final String progress;
  final bool done;
}

const wardrobe = [
  WearItem('기본 스크리블', 0, true),
  WearItem('헤어', 500, false),
  WearItem('장신구', 700, false),
  WearItem('상의', 900, false),
  WearItem('하의', 1200, false),
  WearItem('신발', 1500, false),
];

const quests = [
  Quest('곡 3회 플레이', '500', '2 / 3', false),
  Quest('GOOD 이하 없이 클리어', '50', '완료', true),
  Quest('콤보 50 달성', '700', '34 / 50', false),
  Quest('상점에서 아이템 구매', '900', '0 / 1', false),
];

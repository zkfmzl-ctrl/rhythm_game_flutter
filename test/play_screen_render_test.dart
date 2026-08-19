import 'package:distorted_rhythm/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void useLandscapePhoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(2340, 1080);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpScreen(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(child: child),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('main menu screens do not overflow on landscape phone',
      (tester) async {
    useLandscapePhoneSize(tester);

    final screens = <Widget>[
      HomeScreen(onTab: (_) {}, onStart: () {}),
      const CharacterScreen(),
      CustomScreen(
          gems: 2680, selectedWear: wardrobe.first.name, onEquip: (_) {}),
      const QuestScreen(),
      ShopScreen(coins: 12450, gems: 2680, onBuy: () {}),
      SettingsScreen(
        musicVolume: 80,
        effectVolume: 70,
        vibration: true,
        laneSpeed: 1,
        onMusic: (_) {},
        onEffect: (_) {},
        onVibration: (_) {},
        onLaneSpeed: (_) {},
      ),
    ];

    for (final screen in screens) {
      await pumpScreen(tester, screen);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('SongSelectScreen tile title remains above card background',
      (tester) async {
    useLandscapePhoneSize(tester);

    await pumpScreen(
      tester,
      SongSelectScreen(
        initialSong: songs.first,
        initialDifficulty: Difficulty.hard,
        onSelectSong: (_) {},
        onSelectDifficulty: (_) {},
        onStart: () {},
      ),
    );

    expect(tester.takeException(), isNull);

    final titleFinder = find.textContaining('01.');
    expect(titleFinder, findsOneWidget);

    final titleWidget = tester.widget<Text>(titleFinder);
    expect(titleWidget.style?.color, const Color(0xff000000));
    expect(titleWidget.style?.fontWeight, FontWeight.w900);
  });

  testWidgets('PlayScreen renders play background and gameplay layers',
      (tester) async {
    useLandscapePhoneSize(tester);
    final game = GameState(
      notes: [
        RhythmNote(id: 1, lane: 2, hitAt: 1350, long: false),
        RhythmNote(id: 2, lane: 3, hitAt: 1600, long: true),
      ],
      startedAt: DateTime.now(),
    )
      ..elapsed = 1000
      ..combo = 47
      ..score = 178650
      ..lastJudge = Judge.perfect;

    await tester.pumpWidget(
      MaterialApp(
        home: PlayScreen(
          game: game,
          song: songs.first,
          difficulty: Difficulty.hard,
          onLane: (_) {},
          onReplay: () {},
          onExit: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FittedBox), findsOneWidget);
    expect(find.byType(NoteBoardLayer), findsOneWidget);
    expect(find.byType(MovingNotesLayer), findsOneWidget);
    expect(find.byType(JudgementLayer), findsOneWidget);

    final assetNames = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((image) => image.assetName)
        .toSet();

    expect(assetNames, contains('assets/backgrounds/play2.png'));
    expect(assetNames, contains('assets/character/character_01.png'));
    expect(assetNames, isNot(contains('assets/character/pose.png')));
    expect(assetNames, isNot(contains('assets/items/hand/hand.png')));
  });
}

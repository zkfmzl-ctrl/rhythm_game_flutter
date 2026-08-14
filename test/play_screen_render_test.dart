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

  testWidgets('HomeScreen menu cards fit landscape phone height',
      (tester) async {
    useLandscapePhoneSize(tester);

    await pumpScreen(tester, HomeScreen(onTab: (_) {}, onStart: () {}));

    expect(tester.takeException(), isNull);
    expect(find.text('게임 시작'), findsOneWidget);
    expect(find.text('곡 선택'), findsOneWidget);
  });

  testWidgets('CharacterScreen scrolls instead of overflowing', (tester) async {
    useLandscapePhoneSize(tester);

    await pumpScreen(tester, const CharacterScreen());

    expect(tester.takeException(), isNull);
    expect(find.text('캐릭터'), findsOneWidget);
    expect(find.text('선택 중'), findsOneWidget);
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
    expect(find.text('01. 왜곡된 리듬'), findsOneWidget);
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

    expect(find.byType(FittedBox), findsOneWidget);
    expect(find.byType(NoteBoardLayer), findsOneWidget);
    expect(find.byType(MovingNotesLayer), findsOneWidget);
    expect(find.byType(JudgementLayer), findsOneWidget);
    expect(find.byType(_AssetImageProbe), findsNothing);

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

class _AssetImageProbe extends StatelessWidget {
  const _AssetImageProbe();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

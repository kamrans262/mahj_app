import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/matches/data/invite_players_preview_data.dart';
import 'package:mahj_app/features/matches/data/my_matches_preview_data.dart';
import 'package:mahj_app/features/matches/presentation/widgets/invite_result_card.dart';
import 'package:mahj_app/features/matches/presentation/widgets/my_match_preview_card.dart';

void main() {
  testWidgets('MyMatchPreviewCard is safe inside a vertical sliver list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final item = MyMatchesPreviewData.create().upcoming.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    MyMatchPreviewCard(item: item),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MyMatchPreviewCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('InviteResultCard is safe inside a vertical sliver list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final match = MyMatchesPreviewData.create().upcoming.first.match;
    final result = InvitePlayersPreviewData.forMatch(match).first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    InviteResultCard(
                      result: result,
                      isSelected: false,
                      onTap: () {},
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(InviteResultCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

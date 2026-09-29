import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/features/matches/domain/my_matches_data.dart';
import 'package:mahj_app/features/matches/presentation/my_matches_screen.dart';

void main() {
  testWidgets('Invites card uses the dedicated invitation callback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    MyMatchesItem? tappedItem;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MyMatchesScreen(
            initialTab: MyMatchesTab.invites,
            onInvitationTap: (item) => tappedItem = item,
            onNotificationTap: () {},
            onMessageTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final inviteCard = find.byKey(const ValueKey('my-match-card-my-invite-1'));
    expect(inviteCard, findsOneWidget);

    await tester.ensureVisible(inviteCard);
    await tester.pump();
    await tester.tap(inviteCard);
    await tester.pump();

    expect(tappedItem, isNotNull);
    expect(tappedItem!.match.id, 'my-invite-1');
    expect(tester.takeException(), isNull);
  });
}

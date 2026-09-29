import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/router/app_router.dart';
import 'package:mahj_app/features/chat/presentation/match_chat_screen.dart';
import 'package:mahj_app/features/home/data/home_preview_data.dart';
import 'package:mahj_app/features/profile/presentation/player_profile_screen.dart';

void main() {
  testWidgets('tapping another Chat Player opens Player Profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final match = HomePreviewData.create().nearbyMatches.first;

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(AppRoutes.matchChat, arguments: match);
                },
                child: const Text('Open chat'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Open chat'), findsOneWidget);
    await tester.tap(find.text('Open chat'));
    await tester.pumpAndSettle();
    expect(find.byType(MatchChatScreen), findsOneWidget);

    await tester.tap(find.text('Alex').first);
    await tester.pumpAndSettle();

    expect(find.byType(PlayerProfileScreen), findsOneWidget);
    expect(find.text('Players Profile'), findsOneWidget);
    expect(find.text('Alex Turner'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

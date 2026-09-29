import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahj_app/app/theme/app_colors.dart';
import 'package:mahj_app/app/theme/app_radius.dart';
import 'package:mahj_app/app/theme/app_spacing.dart';
import 'package:mahj_app/core/widgets/app_button.dart';
import 'package:mahj_app/features/home/domain/home_match.dart';
import 'package:mahj_app/features/matches/presentation/match_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HomeMatch createMatch({
    int currentPlayers = 2,
    MatchStatus status = MatchStatus.open,
  }) {
    return HomeMatch(
      id: 'join-dialog-test-match',
      sportName: 'Football',
      location: 'Central Park View',
      startsAt: DateTime(2026, 5, 25, 18),
      currentPlayers: currentPlayers,
      maxPlayers: 4,
      status: status,
    );
  }

  Future<void> pumpDetails(
    WidgetTester tester, {
    MatchJoinCallback? onJoinMatch,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          );
        },
        home: MatchDetailsScreen(
          match: createMatch(),
          onJoinMatch: onJoinMatch,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openDialog(WidgetTester tester) async {
    final detailsScrollView = find.descendant(
      of: find.byKey(const ValueKey('match-details-scroll-view')),
      matching: find.byType(Scrollable),
    );

    expect(detailsScrollView, findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Join Match'),
      180,
      scrollable: detailsScrollView,
    );
    await tester.tap(find.text('Join Match'));
    await tester.pumpAndSettle();
  }

  testWidgets('Join Match opens the reusable confirmation modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDetails(tester);
    await openDialog(tester);

    expect(find.text('Join Confirmation'), findsOneWidget);
    expect(
      find.text('Are you sure you want to join this match?'),
      findsOneWidget,
    );

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('app-modal-card-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    final border = decoration.border! as Border;

    expect(decoration.color, AppColors.subtleSurface);
    expect(decoration.borderRadius, BorderRadius.circular(AppRadius.sheetTop));
    expect(border.top.width, 1);
    expect(border.top.color, AppColors.subtleBorder);
    expect(decoration.boxShadow, isNotNull);
    expect(
      decoration.boxShadow!.single.color,
      AppColors.confirmationDialogShadow,
    );
    expect(decoration.boxShadow!.single.offset, const Offset(0, 2));
    expect(decoration.boxShadow!.single.blurRadius, 4);

    final dialogRect = tester.getRect(
      find.byKey(const ValueKey('app-modal-card-surface')),
    );
    expect(dialogRect.left, closeTo(AppSpacing.pageHorizontal, 0.01));
    expect(390 - dialogRect.right, closeTo(AppSpacing.pageHorizontal, 0.01));

    final contentPadding = tester.widget<Padding>(
      find.byKey(const ValueKey('app-modal-card-padding')),
    );
    expect(
      contentPadding.padding,
      const EdgeInsets.symmetric(
        horizontal: AppSpacing.confirmationDialogHorizontal,
        vertical: AppSpacing.confirmationDialogVertical,
      ),
    );

    final cancel = tester.widget<AppButton>(
      find.byKey(const ValueKey('confirmation-cancel-button')),
    );
    final confirm = tester.widget<AppButton>(
      find.byKey(const ValueKey('confirmation-confirm-button')),
    );
    expect(cancel.label, 'Cancel');
    expect(confirm.label, 'Join');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancel dismisses the popup without changing match state', (
    tester,
  ) async {
    var joinCalls = 0;
    await pumpDetails(
      tester,
      onJoinMatch: (match) async {
        joinCalls += 1;
        return match;
      },
    );
    await openDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Join Confirmation'), findsNothing);
    expect(find.text('Match Details'), findsOneWidget);
    expect(joinCalls, 0);
  });

  testWidgets(
    'Join waits for backend result, prevents duplicate taps, and updates UI',
    (tester) async {
      final completer = Completer<HomeMatch>();
      var joinCalls = 0;

      await pumpDetails(
        tester,
        onJoinMatch: (match) {
          joinCalls += 1;
          return completer.future;
        },
      );
      await openDialog(tester);

      await tester.tap(find.text('Join'));
      await tester.pump();

      expect(joinCalls, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('confirmation-confirm-button')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(joinCalls, 1);

      completer.complete(createMatch(currentPlayers: 3));
      await tester.pumpAndSettle();

      expect(find.text('Join Confirmation'), findsNothing);
      expect(find.text('3/4'), findsOneWidget);
      expect(find.text('3 joined · 1 opening left'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Join failure keeps dialog open and shows existing snackbar feedback',
    (tester) async {
      await pumpDetails(
        tester,
        onJoinMatch: (match) async {
          throw Exception('network');
        },
      );
      await openDialog(tester);

      await tester.tap(find.text('Join'));
      await tester.pumpAndSettle();

      expect(find.text('Join Confirmation'), findsOneWidget);
      expect(
        find.text('Could not join the match. Please try again.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('Backdrop does not dismiss confirmation but Android back does', (
    tester,
  ) async {
    await pumpDetails(tester);
    await openDialog(tester);

    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('Join Confirmation'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Join Confirmation'), findsNothing);
    expect(find.text('Match Details'), findsOneWidget);
  });

  testWidgets('Large accessibility text stacks actions without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDetails(tester, textScale: 1.8);
    await openDialog(tester);

    final cancelRect = tester.getRect(
      find.byKey(const ValueKey('confirmation-cancel-button')),
    );
    final joinRect = tester.getRect(
      find.byKey(const ValueKey('confirmation-confirm-button')),
    );

    expect(joinRect.top, greaterThan(cancelRect.bottom));
    expect(tester.takeException(), isNull);
  });
}
